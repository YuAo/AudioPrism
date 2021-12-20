    import XCTest
    import AVFoundation
    import Fixtures
    import AudioPrism

    final class AudioPrismTests: XCTestCase {
        
        func testNoInputData() throws {
            let prism = try AudioPrism(options: AudioPrism.Options())
            XCTAssert(prism.timeDomainData == nil)
            XCTAssert(prism.frequencyData == nil)
        }
        
        func testNotEnoughInputData() throws {
            let prism = try AudioPrism(options: AudioPrism.Options(fftSize: 2048))
            let file = try AVAudioFile(forReading: Fixtures.audioURL, commonFormat: .pcmFormatFloat32, interleaved: false)
            let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 1024))
            try file.read(into: buffer)
            try prism.update(with: buffer)
            XCTAssert(prism.timeDomainData == nil)
            XCTAssert(prism.frequencyData == nil)
        }
        
        func testTimeDomainData() throws {
            let prism = try AudioPrism(options: AudioPrism.Options())
            let file = try AVAudioFile(forReading: Fixtures.audioURL, commonFormat: .pcmFormatFloat32, interleaved: false)
            let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 2048))
            try file.read(into: buffer)
            try prism.update(with: buffer)
            XCTAssert(prism.timeDomainData?.floatValues == [Float](UnsafeBufferPointer<Float>(start: buffer.floatChannelData?.pointee, count: 2048)))
        }
        
        func testFrequencyData() throws {
            let prism = try AudioPrism(options: AudioPrism.Options())
            let file = try AVAudioFile(forReading: Fixtures.audioURL, commonFormat: .pcmFormatFloat32, interleaved: false)
            let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 2048))
            try file.read(into: buffer)
            try prism.update(with: buffer)
            XCTAssert(prism.frequencyData?.uint8Values == [75, 95, 115, 126, 121, 118, 180, 211, 228, 226, 204, 195, 205, 197, 164, 96, 61, 134, 135, 113, 110, 139, 152, 144, 118, 104, 103, 102, 106, 122, 127, 119, 110, 103, 89, 107, 111, 86, 94, 88, 63, 59, 88, 113, 129, 133, 123, 104, 78, 49, 55, 78, 115, 139, 144, 133, 122, 123, 107, 71, 62, 57, 36, 62, 82, 84, 73, 66, 78, 75, 46, 65, 65, 46, 76, 90, 87, 76, 60, 45, 48, 38, 34, 54, 66, 68, 66, 54, 61, 73, 92, 97, 81, 77, 79, 59, 62, 83, 77, 47, 66, 77, 73, 69, 68, 62, 50, 39, 5, 0, 12, 35, 54, 60, 56, 45, 36, 60, 60, 57, 50, 0, 26, 40, 51, 53, 54, 53, 49, 44, 38, 17, 0, 2, 6, 0, 8, 28, 43, 47, 43, 47, 46, 45, 48, 47, 39, 22, 15, 17, 13, 18, 31, 36, 41, 48, 49, 41, 32, 25, 21, 25, 21, 12, 18, 21, 9, 0, 0, 0, 0, 3, 2, 0, 4, 8, 9, 3, 0, 0, 0, 0, 0, 1, 9, 11, 16, 16, 19, 18, 14, 11, 0, 0, 0, 0, 0, 0, 21, 27, 6, 0, 4, 0, 0, 0, 0, 0, 2, 5, 0, 0, 0, 0, 0, 0, 14, 30, 19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 11, 15, 19, 19, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 12, 15, 16, 11, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        }
    }
