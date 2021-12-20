import AVFoundation
import Accelerate
import OSLog

/** AudioPrism implements the `AnalyserNode` functionality defined in the Web Audio API.
    
    ## Thread Safety
 
    It's safe to share an `AudioPrism` object among threads.
 */
public final class AudioPrism: @unchecked Sendable {
    
    /// Options for creating an `AudioPrism` object.
    public struct Options: Hashable, Codable, Sendable {
        
        /**
         Initializes a new `AudioPrism.Options`.
         
         - Parameters:
         
            - fftSize: The size of the FFT used for frequency-domain analysis (in sample-frames).
         
            - maxDecibels: The maximum power value in the scaling range for the FFT analysis data for conversion to unsigned byte values.
         
            - minDecibels: The minimum power value in the scaling range for the FFT analysis data for conversion to unsigned byte values.
         
            - smoothingTimeConstant: A value from 0 -> 1 where 0 represents no time averaging with the last analysis frame.
         
         - Returns: An `AudioPrism.Options` struct.
         */
        public init(fftSize: Int = 2048,
                    maxDecibels: Float = -30,
                    minDecibels: Float = -100,
                    smoothingTimeConstant: Float = 0.8) {
            self.fftSize = fftSize
            self.maxDecibels = maxDecibels
            self.minDecibels = minDecibels
            self.smoothingTimeConstant = smoothingTimeConstant
        }
        
        /// The size of the FFT used for frequency-domain analysis (in sample-frames). This must be a power of two in the range 32 to 32768, otherwise an `invalidFFTSize` error is thrown.
        public var fftSize: Int
        
        /// The maximum power value in the scaling range for the FFT analysis data for conversion to unsigned byte values. The default value is -30. If the value of this attribute is set to a value less than or equal to minDecibels, an `invalidDecibels` error is thrown.
        public var maxDecibels: Float
        
        /// The minimum power value in the scaling range for the FFT analysis data for conversion to unsigned byte values. The default value is -100. If the value of this attribute is set to a value more than or equal to maxDecibels, an `invalidDecibels` error is thrown.
        public var minDecibels: Float
        
        /// A value from 0 -> 1 where 0 represents no time averaging with the last analysis frame. The default value is 0.8. If the value of this attribute is set to a value less than 0 or more than 1, an `invalidSmoothingTimeConstant` error is thrown.
        public var smoothingTimeConstant: Float
    }
    
    /// Time-domain data.
    public struct TimeDomainData: Hashable, Codable, Sendable {
        /**
         The float array of the waveform data.
         
         The most recent fftSize frames are returned (after downmixing).
         */
        public var floatValues: [Float]
        
        /**
         The unsigned byte array of the waveform data.
         
         The values stored in the unsigned byte array are computed in the following way. Let 𝑥[𝑘] be the time-domain data. Then the byte value, 𝑏[𝑘], is
         
         ```
         𝑏[𝑘]=⌊128(1+𝑥[𝑘])⌋.
         ```
         
         If 𝑏[𝑘] lies outside the range 0 to 255, 𝑏[𝑘] is clipped to lie in that range.
         */
        public var uint8Values: [UInt8]
    }
    
    /// Frequency data.
    public struct FrequencyData: Hashable, Codable, Sendable {
        /**
         The float array of the frequency data.
        
         The most recent fftSize frames are used in computing the frequency data. The frequency data are in dB units.
         */
        public var floatValues: [Float]
        
        /**
         The unsigned byte array of the frequency data.
     
         The values stored in the unsigned byte array are computed in the following way. Let 𝑌[𝑘] be the frequency data. Then the byte value, 𝑏[𝑘], is
         
         ```
         𝑏[𝑘]=⌊255/(dB𝑚𝑎𝑥−dB𝑚𝑖𝑛) * (𝑌[𝑘]−dB𝑚𝑖𝑛)⌋
         ```
         
         where dB𝑚𝑖𝑛 is minDecibels and dB𝑚𝑎𝑥 is maxDecibels. If 𝑏[𝑘] lies outside the range of 0 to 255, 𝑏[𝑘] is clipped to lie in that range.
        */
        public var uint8Values: [UInt8]
    }
    
    public enum Error: Swift.Error {
        case invalidFFTSize
        case invalidDecibels
        case invalidSmoothingTimeConstant
        
        case cannotSetupFFT
        case unsupportedPCMBufferFormat
        case unsupportedSampleBufferFormat
        case cannotCreateAudioBufferConverter
        case cannotCreateAudioBuffer
    }
    
    /// Half the FFT size.
    public let frequencyBinCount: Int
    
    /// Options used to create the `AudioPrism` object.
    public let options: Options
    
    private static let allowedFFTSizes = Set([32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768])
    private static let maximumFFTSize = 32768
    
    private let fft: FFTSetup
    private let log2n: vDSP_Length
    
    /// Down-mix to mono and convert samples to float32
    private class AudioBufferConverter {
        private var fromFormat: AVAudioFormat?
        private var converter: AVAudioConverter?
        func convert(buffer: AVAudioPCMBuffer) throws -> AVAudioPCMBuffer {
            let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: buffer.format.sampleRate, channels: 1, interleaved: false)!
            if buffer.format.isEqual(format) {
                return buffer
            }
            if fromFormat?.isEqual(buffer.format) == true {
                //reuse the converter
            } else {
                converter = AVAudioConverter(from: buffer.format, to: format)
            }
            guard let converter = self.converter else {
                throw AudioPrism.Error.cannotCreateAudioBufferConverter
            }
            fromFormat = buffer.format
            guard let toBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameLength) else {
                throw AudioPrism.Error.cannotCreateAudioBuffer
            }
            try converter.convert(to: toBuffer, from: buffer)
            return toBuffer
        }
    }
    
    private let converter: AudioBufferConverter = AudioBufferConverter()
    
    private var sampleBuffer: [Float] = []
    private var previousFFTValues: [Float]
    
    private let window: [Float]
    
    private var _timeDomainData: TimeDomainData?
    private var _frequencyData: FrequencyData?
    
    private let lock = UnfairLock()

    /// Initializes a new `AudioPrism` object with `options`.
    public init(options: Options = Options()) throws {
        guard AudioPrism.allowedFFTSizes.contains(options.fftSize) else {
            throw Error.invalidFFTSize
        }
        guard options.minDecibels < options.maxDecibels else {
            throw Error.invalidDecibels
        }
        guard options.smoothingTimeConstant >= 0 && options.smoothingTimeConstant <= 1 else {
            throw Error.invalidSmoothingTimeConstant
        }
        let log2n = vDSP_Length(log2(Float(options.fftSize)))
        self.log2n = log2n
        guard let fft = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            throw Error.cannotSetupFFT
        }
        self.fft = fft
        self.options = options
        self.frequencyBinCount = options.fftSize/2
        self.previousFFTValues = [Float](repeating: 0, count: frequencyBinCount)

        var window = [Float](repeating: 0, count: options.fftSize)
        vDSP_blkman_window(&window, vDSP_Length(options.fftSize), 0)
        self.window = window
    }
    
    deinit {
        vDSP_destroy_fftsetup(fft)
    }
    
    /// The most recent `fftSize` frames of time-domain data.
    public var timeDomainData: TimeDomainData? {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        guard sampleBuffer.count >= options.fftSize else {
            return nil
        }
        
        if let data = _timeDomainData {
            return data
        }
        
        let samples = Array(sampleBuffer.suffix(options.fftSize))
        var timeDomainUInt8Values: [UInt8] = [UInt8](repeating: 0, count: samples.count)
        samples.withUnsafeBytes({ samplesPtr in
            timeDomainUInt8Values.withUnsafeMutableBytes({ uint8ValuesPtr in
                var source = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: samplesPtr.baseAddress!), height: 1, width: vImagePixelCount(samples.count), rowBytes: samples.count * MemoryLayout<Float>.size)
                var destination = vImage_Buffer(data: uint8ValuesPtr.baseAddress!, height: 1, width: vImagePixelCount(samples.count), rowBytes: samples.count)
                vImageConvert_PlanarFtoPlanar8(&source, &destination, 1, -1, 0)
            })
        })
        let data = TimeDomainData(floatValues: samples, uint8Values: timeDomainUInt8Values)
        _timeDomainData = data
        return data
    }
    
    /// The most recent frequency data. The most recent `fftSize` frames are used in computing the frequency data.
    public var frequencyData: FrequencyData? {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        guard sampleBuffer.count >= options.fftSize else {
            return nil
        }
        
        if let data = _frequencyData {
            return data
        }
        
        var samples = Array(sampleBuffer.suffix(options.fftSize))
        
        var frequencyData = [Float](repeating: 0, count: frequencyBinCount)
        var uint8Values = [UInt8](repeating: 0, count: frequencyBinCount)
        
        var complexReals = [Float](repeating: 0, count: frequencyBinCount)
        var complexImaginaries = [Float](repeating: 0, count: frequencyBinCount)
        
        // Normalize so than an input sine wave at 0dBfs registers as 0dBfs (undo FFT scaling factor).
        let magnitudeScale = 1.0 / Float(options.fftSize)
        
        vDSP_vmul(samples, 1, window, 1, &samples, 1, vDSP_Length(options.fftSize))
        samples.withUnsafeBytes { samplesPtr in
            complexReals.withUnsafeMutableBufferPointer { realPtr in
                complexImaginaries.withUnsafeMutableBufferPointer { imagPtr in
                    var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!,
                                                       imagp: imagPtr.baseAddress!)
                    vDSP_ctoz(samplesPtr.bindMemory(to: DSPComplex.self).baseAddress!, 2,
                              &splitComplex, 1,
                              vDSP_Length(frequencyBinCount))
                    vDSP_fft_zrip(fft,
                                  &splitComplex, 1,
                                  log2n,
                                  FFTDirection(kFFTDirection_Forward))
                    
                    // To provide the best possible execution speeds, the vDSP library's functions don't always adhere strictly
                    // to textbook formulas for Fourier transforms, and must be scaled accordingly.
                    // (See https://developer.apple.com/library/archive/documentation/Performance/Conceptual/vDSP_Programming_Guide/UsingFourierTransforms/UsingFourierTransforms.html#//apple_ref/doc/uid/TP40005147-CH3-SW5)
                    // In the case of a Real forward Transform like above: RFimp = RFmath * 2 so we need to divide the output
                    // by 2 to get the correct value.
                    vDSP_vsmul(realPtr.baseAddress!, 1, [0.5], realPtr.baseAddress!, 1, vDSP_Length(frequencyBinCount))
                    vDSP_vsmul(imagPtr.baseAddress!, 1, [0.5], imagPtr.baseAddress!, 1, vDSP_Length(frequencyBinCount))
                    
                    // Blow away the packed nyquist component.
                    imagPtr[0] = 0
                    
                    var previousValues = self.previousFFTValues
                    vDSP_zvabs(&splitComplex, 1, &frequencyData, 1, vDSP_Length(frequencyBinCount))
                    vDSP_vsmul(frequencyData, 1, [(1.0 - options.smoothingTimeConstant) * magnitudeScale], &frequencyData, 1, vDSP_Length(frequencyBinCount))
                    vDSP_vsmul(previousValues, 1, [options.smoothingTimeConstant], &previousValues, 1, vDSP_Length(frequencyBinCount))
                    vDSP_vadd(frequencyData, 1, previousValues, 1, &frequencyData, 1, vDSP_Length(frequencyBinCount))
                    self.previousFFTValues = frequencyData
                    
                    vDSP_vsadd(frequencyData, 1, [1e-20], &frequencyData, 1, vDSP_Length(frequencyBinCount))
                    vvlog10f(&frequencyData, frequencyData, [Int32(frequencyBinCount)])
                    vDSP_vsmul(frequencyData, 1, [20], &frequencyData, 1, vDSP_Length(frequencyBinCount))
                }
            }
        }
        
        frequencyData.withUnsafeBytes({ frequencyDataPtr in
            uint8Values.withUnsafeMutableBytes({ uint8ValuesPtr in
                var source = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: frequencyDataPtr.baseAddress!), height: 1, width: vImagePixelCount(frequencyBinCount), rowBytes: frequencyBinCount * MemoryLayout<Float>.size)
                var destination = vImage_Buffer(data: uint8ValuesPtr.baseAddress!, height: 1, width: vImagePixelCount(frequencyBinCount), rowBytes: frequencyBinCount)
                vImageConvert_PlanarFtoPlanar8(&source, &destination, options.maxDecibels, options.minDecibels, 0)
            })
        })
        
        let data = FrequencyData(floatValues: frequencyData, uint8Values: uint8Values)
        _frequencyData = data
        return data
    }
    
    /// Update the `AudioPrism` object with an `AVAudioPCMBuffer`.
    public func update(with audioBuffer: AVAudioPCMBuffer) throws {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        let convertedBuffer = try converter.convert(buffer: audioBuffer)
        sampleBuffer.append(contentsOf: UnsafeBufferPointer<Float>(start: convertedBuffer.floatChannelData!.pointee, count: Int(convertedBuffer.frameLength)))
        if sampleBuffer.count > AudioPrism.maximumFFTSize {
            sampleBuffer.removeFirst(sampleBuffer.count - AudioPrism.maximumFFTSize)
        }
        
        _frequencyData = nil
        _timeDomainData = nil
    }
    
    /// Reset the `AudioPrism` object.
    public func reset() {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        sampleBuffer = []
        previousFFTValues = [Float](repeating: 0, count: frequencyBinCount)
        _frequencyData = nil
        _timeDomainData = nil
    }
}

extension AudioPrism {
    /// An `os_unfair_lock` wrapper.
    private class UnfairLock {
        private let unfairLock: os_unfair_lock_t
        
        public init() {
            unfairLock = .allocate(capacity: 1)
            unfairLock.initialize(to: os_unfair_lock())
        }
        
        deinit {
            unfairLock.deinitialize(count: 1)
            unfairLock.deallocate()
        }
        
        public func lock() {
            os_unfair_lock_lock(unfairLock)
        }
        
        public func unlock() {
            os_unfair_lock_unlock(unfairLock)
        }
    }
}
