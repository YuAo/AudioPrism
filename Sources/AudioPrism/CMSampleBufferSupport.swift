//
//  File.swift
//  
//
//  Created by YuAo on 2021/8/23.
//

import Foundation
import AVFoundation

extension AudioPrism {
    
    /// Update the `AudioPrism` object with a `CMSampleBuffer`.
    public func update(with sampleBuffer: CMSampleBuffer) throws {
        guard let formatDescriptor = sampleBuffer.formatDescription as CMAudioFormatDescription?, formatDescriptor.mediaType == .audio else {
            throw Error.unsupportedSampleBufferFormat
        }
        let audioFormat = AVAudioFormat(cmAudioFormatDescription: formatDescriptor)
        guard audioFormat.commonFormat == .pcmFormatFloat32 ||
                audioFormat.commonFormat == .pcmFormatFloat64 ||
                audioFormat.commonFormat == .pcmFormatInt16 ||
                audioFormat.commonFormat == .pcmFormatInt32
        else {
            throw Error.unsupportedSampleBufferFormat
        }
        guard let fromBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(sampleBuffer.numSamples)) else {
            throw Error.cannotCreateAudioBuffer
        }
        try sampleBuffer.copyPCMData(fromRange: 0..<sampleBuffer.numSamples, into: fromBuffer.mutableAudioBufferList)
        try update(with: fromBuffer)
    }
}
