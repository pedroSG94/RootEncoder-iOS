//
//  Extensions.swift
//  encoder
//
//  Created by Pedro  on 27/9/23.
//

import Foundation
import AVFAudio

extension Date {
    var millisecondsSince1970:Int64 {
        Int64((timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

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
}

extension AVAudioTime {
    static let zero = AVAudioTime(hostTime: 0)

    func makeTime() -> CMTime {
        return .init(seconds: AVAudioTime.seconds(forHostTime: hostTime), preferredTimescale: 1000000000)
    }
}
