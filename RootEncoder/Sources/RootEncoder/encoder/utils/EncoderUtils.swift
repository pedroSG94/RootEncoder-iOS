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
        return makeSampleBuffer(when.makeTime())
    }
    
    final func makeSampleBuffer(_ when: CMTime) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?
        CMAudioSampleBufferCreateWithPacketDescriptions(
            allocator: nil,
            dataBuffer: nil,
            dataReady: false,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: format.formatDescription,
            sampleCount: Int(frameLength),
            presentationTimeStamp: when,
            packetDescriptions: nil,
            sampleBufferOut: &sampleBuffer
        )
        guard let sampleBuffer else { return nil }
        CMSampleBufferSetDataBufferFromAudioBufferList(
            sampleBuffer,
            blockBufferAllocator: kCFAllocatorDefault,
            blockBufferMemoryAllocator: kCFAllocatorDefault,
            flags: 0,
            bufferList: audioBufferList
        )
        return sampleBuffer
    }
    
    func audioBufferToBytes() -> [UInt8] {
        let srcLeft = self.audioBufferList.pointee.mBuffers.mData!
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
    
    @discardableResult
    @inlinable
    final func copy(_ audioBuffer: AVAudioBuffer) -> Bool {
        guard let audioBuffer = audioBuffer as? AVAudioPCMBuffer, frameLength == audioBuffer.frameLength else {
            return false
        }
        let numSamples = Int(frameLength)
        if format.isInterleaved {
            let channelCount = Int(format.channelCount)
            switch format.commonFormat {
            case .pcmFormatInt16:
                memcpy(int16ChannelData?[0], audioBuffer.int16ChannelData?[0], numSamples * channelCount * 2)
            case .pcmFormatInt32:
                memcpy(int32ChannelData?[0], audioBuffer.int32ChannelData?[0], numSamples * channelCount * 4)
            case .pcmFormatFloat32:
                memcpy(floatChannelData?[0], audioBuffer.floatChannelData?[0], numSamples * channelCount * 4)
            default:
                break
            }
        } else {
            for i in 0..<Int(format.channelCount) {
                switch format.commonFormat {
                case .pcmFormatInt16:
                    memcpy(int16ChannelData?[i], audioBuffer.int16ChannelData?[i], numSamples * 2)
                case .pcmFormatInt32:
                    memcpy(int32ChannelData?[i], audioBuffer.int32ChannelData?[i], numSamples * 4)
                case .pcmFormatFloat32:
                    memcpy(floatChannelData?[i], audioBuffer.floatChannelData?[i], numSamples * 4)
                default:
                    break
                }
            }
        }
        return true
    }
    
    func mute(enabled: Bool) -> AVAudioPCMBuffer {
        if !enabled {
            return self
        }
        let numSamples = Int(frameLength)
        if format.isInterleaved {
            let channelCount = Int(format.channelCount)
            switch format.commonFormat {
            case .pcmFormatInt16:
                int16ChannelData?[0].update(repeating: 0, count: numSamples * channelCount)
            case .pcmFormatInt32:
                int32ChannelData?[0].update(repeating: 0, count: numSamples * channelCount)
            case .pcmFormatFloat32:
                floatChannelData?[0].update(repeating: 0, count: numSamples * channelCount)
            default:
                break
            }
        } else {
            for i in 0..<Int(format.channelCount) {
                switch format.commonFormat {
                case .pcmFormatInt16:
                    int16ChannelData?[i].update(repeating: 0, count: numSamples)
                case .pcmFormatInt32:
                    int32ChannelData?[i].update(repeating: 0, count: numSamples)
                case .pcmFormatFloat32:
                    floatChannelData?[i].update(repeating: 0, count: numSamples)
                default:
                    break
                }
            }
        }
        return self
    }
}

extension AVAudioTime {
    static let zero = AVAudioTime(hostTime: 0)

    func makeTime() -> CMTime {
        return .init(seconds: AVAudioTime.seconds(forHostTime: hostTime), preferredTimescale: 1000000000)
    }
}

extension CMTime {
    func makeAudioTime() -> AVAudioTime {
        return .init(sampleTime: value, atRate: Double(timescale))
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
