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
    func configureSampleBuffer() -> CMSampleBuffer? {
            let pcmBuffer = self
            let audioBufferList = pcmBuffer.mutableAudioBufferList
            let asbd = pcmBuffer.format.streamDescription

            var sampleBuffer: CMSampleBuffer? = nil
            var format: CMFormatDescription? = nil
            
            var status = CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault,
                                                             asbd: asbd,
                                                       layoutSize: 0,
                                                           layout: nil,
                                                           magicCookieSize: 0,
                                                           magicCookie: nil,
                                                           extensions: nil,
                                                           formatDescriptionOut: &format);
            if (status != noErr) { return nil; }
            
            var timing: CMSampleTimingInfo = CMSampleTimingInfo(duration: CMTime(value: 1, timescale: Int32(asbd.pointee.mSampleRate)),
                                                                presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
                                                                decodeTimeStamp: CMTime.invalid)
            status = CMSampleBufferCreate(allocator: kCFAllocatorDefault,
                                          dataBuffer: nil,
                                          dataReady: false,
                                          makeDataReadyCallback: nil,
                                          refcon: nil,
                                          formatDescription: format,
                                          sampleCount: CMItemCount(pcmBuffer.frameLength),
                                          sampleTimingEntryCount: 1,
                                          sampleTimingArray: &timing,
                                          sampleSizeEntryCount: 0,
                                          sampleSizeArray: nil,
                                          sampleBufferOut: &sampleBuffer);
            if (status != noErr) { NSLog("CMSampleBufferCreate returned error: \(status)"); return nil }
            
            status = CMSampleBufferSetDataBufferFromAudioBufferList(sampleBuffer!,
                                                                    blockBufferAllocator: kCFAllocatorDefault,
                                                                    blockBufferMemoryAllocator: kCFAllocatorDefault,
                                                                    flags: 0,
                                                                    bufferList: audioBufferList);
            if (status != noErr) { NSLog("CMSampleBufferSetDataBufferFromAudioBufferList returned error: \(status)"); return nil; }
            
            return sampleBuffer
        }

}

