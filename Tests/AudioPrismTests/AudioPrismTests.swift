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
            XCTAssert(prism.frequencyData?.uint8Values == [97, 117, 137, 148, 143, 140, 202, 232, 250, 247, 225, 217, 227, 219, 186, 118, 83, 155, 157, 135, 132, 161, 174, 165, 140, 126, 125, 124, 128, 144, 149, 141, 132, 125, 111, 129, 133, 108, 116, 110, 85, 81, 110, 135, 151, 155, 145, 126, 100, 71, 77, 100, 137, 161, 166, 155, 144, 145, 129, 93, 84, 79, 58, 84, 104, 105, 95, 87, 100, 97, 68, 87, 87, 68, 98, 112, 109, 98, 82, 67, 69, 60, 56, 76, 87, 90, 88, 76, 83, 95, 114, 119, 103, 99, 101, 81, 84, 105, 99, 68, 88, 99, 95, 91, 90, 84, 72, 61, 27, 19, 34, 57, 76, 82, 77, 67, 58, 82, 82, 79, 72, 22, 48, 62, 73, 75, 76, 75, 70, 66, 60, 39, 0, 24, 28, 7, 30, 50, 65, 69, 65, 69, 68, 67, 70, 69, 61, 44, 37, 39, 34, 40, 53, 58, 63, 70, 71, 63, 54, 47, 43, 47, 43, 33, 40, 42, 31, 0, 0, 3, 15, 25, 24, 20, 26, 30, 31, 25, 5, 0, 2, 0, 0, 23, 31, 33, 38, 38, 41, 39, 36, 33, 16, 12, 11, 0, 0, 3, 43, 49, 28, 21, 26, 10, 19, 9, 3, 7, 24, 27, 0, 17, 13, 0, 0, 8, 35, 52, 41, 0, 0, 0, 0, 0, 0, 2, 11, 0, 0, 0, 0, 0, 16, 21, 9, 0, 0, 11, 29, 33, 37, 41, 41, 29, 12, 18, 19, 13, 0, 0, 13, 18, 15, 16, 18, 20, 15, 7, 18, 20, 5, 0, 0, 12, 6, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 21, 32, 34, 37, 37, 33, 19, 5, 0, 13, 2, 13, 26, 22, 9, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 20, 19, 19, 16, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 12, 16, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 0, 0, 2, 5, 3, 5, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 1, 0, 0, 1, 7, 8, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

        }
    }
