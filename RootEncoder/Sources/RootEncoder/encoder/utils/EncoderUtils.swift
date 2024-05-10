//
//  Extensions.swift
//  encoder
//
//  Created by Pedro  on 27/9/23.
//

import Foundation
import AVFAudio

public extension AVAudioPCMBuffer {
    final func makeSampleBuffer(_ when: AVAudioTime) -> CMSampleBuffer? {
        var status: OSStatus = noErr
        var sampleBuffer: CMSampleBuffer?
        status = CMAudioSampleBufferCreateWithPacketDescriptions(
            allocator: nil,
            dataBuffer: nil,
            dataReady: false,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: format.formatDescription,
            sampleCount: Int(frameLength),
            presentationTimeStamp: when.makeTime(),
            packetDescriptions: nil,
            sampleBufferOut: &sampleBuffer
        )
        guard let sampleBuffer else { return nil }
        status = CMSampleBufferSetDataBufferFromAudioBufferList(
            sampleBuffer,
            blockBufferAllocator: kCFAllocatorDefault,
            blockBufferMemoryAllocator: kCFAllocatorDefault,
            flags: 0,
            bufferList: audioBufferList
        )
        return sampleBuffer
    }
    
    func audioBufferToBytes() -> [UInt8] {
        let srcLeft = self.floatChannelData![0]
        let bytesPerFrame = self.format.streamDescription.pointee.mBytesPerFrame
        let numBytes = Int(bytesPerFrame * self.frameLength)
        var audioByteArray = [UInt8](repeating: 0, count: numBytes)
        srcLeft.withMemoryRebound(to: UInt8.self, capacity: numBytes) { srcByteData in
            audioByteArray.withUnsafeMutableBufferPointer {
                $0.baseAddress!.initialize(from: srcByteData, count: numBytes)
            }
        }
        return audioByteArray
    }
}

extension AVAudioTime {
    static let zero = AVAudioTime(hostTime: 0)

    func makeTime() -> CMTime {
        return .init(seconds: AVAudioTime.seconds(forHostTime: hostTime), preferredTimescale: 1000000000)
    }
}

extension UInt32 {
    func toBytes() -> [UInt8] {
        let b1 = UInt8(self & 0x1F)
        let b2 = UInt8(self >> 8)
        let b3 = UInt8(self >> 16)
        let b4 = UInt8(self >> 24)
        return [UInt8](arrayLiteral: b1, b2, b3, b4)
    }
}
