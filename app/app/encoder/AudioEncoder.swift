//
//  AudioEncoder.swift
//  app
//
//  Created by Mac on 07/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation

class AudioBufferFormatHelper {

    static func PCMFormat() -> AVAudioFormat? {
        return AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)
    }

    static func AACFormat() -> AVAudioFormat? {

        var outDesc = AudioStreamBasicDescription(
            mSampleRate: 44100,
            mFormatID: kAudioFormatMPEG4AAC,
            mFormatFlags: 0,
            mBytesPerPacket: 0,
            mFramesPerPacket: 0,
            mBytesPerFrame: 0,
            mChannelsPerFrame: 1,
            mBitsPerChannel: 0,
            mReserved: 0)
        let outFormat = AVAudioFormat(streamDescription: &outDesc)
        return outFormat
    }
}

class AudioBufferConverter {
    static var lpcmToAACConverter: AVAudioConverter! = nil

    static func convertToAAC(from buffer: AVAudioBuffer, error outError: inout NSError?) -> AVAudioCompressedBuffer? {

        let outputFormat = AudioBufferFormatHelper.AACFormat()
        let outBuffer = AVAudioCompressedBuffer(format: outputFormat!, packetCapacity: 8, maximumPacketSize: 768)

        //init converter once
        if lpcmToAACConverter == nil {
            let inputFormat = buffer.format

            lpcmToAACConverter = AVAudioConverter(from: inputFormat, to: outputFormat!)
//            print("available rates \(lpcmToAACConverter.applicableEncodeBitRates)")
//          lpcmToAACConverter!.bitRate = 96000
            lpcmToAACConverter.bitRate = 32000    // have end of stream problems with this, not sure why
        }

        self.convert(withConverter:lpcmToAACConverter, from: buffer, to: outBuffer, error: &outError)

        return outBuffer
    }

    static var aacToLPCMConverter: AVAudioConverter! = nil

    static func convertToPCM(from buffer: AVAudioBuffer, error outError: NSErrorPointer) -> AVAudioPCMBuffer? {

        let outputFormat = AudioBufferFormatHelper.PCMFormat()
        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat!, frameCapacity: 4410) else {
            return nil
        }

        //init converter once
        if aacToLPCMConverter == nil {
            let inputFormat = buffer.format

            aacToLPCMConverter = AVAudioConverter(from: inputFormat, to: outputFormat!)
        }

        self.convert(withConverter: aacToLPCMConverter, from: buffer, to: outBuffer, error: outError)

        return outBuffer
    }

    static func convertToAAC(from data: Data, packetDescriptions: [AudioStreamPacketDescription]) -> AVAudioCompressedBuffer? {

        let nsData = NSData(data: data)
        let inputFormat = AudioBufferFormatHelper.AACFormat()
        let maximumPacketSize = packetDescriptions.map { $0.mDataByteSize }.max()!
        let buffer = AVAudioCompressedBuffer(format: inputFormat!, packetCapacity: AVAudioPacketCount(packetDescriptions.count), maximumPacketSize: Int(maximumPacketSize))
        buffer.byteLength = UInt32(data.count)
        buffer.packetCount = AVAudioPacketCount(packetDescriptions.count)

        buffer.data.copyMemory(from: nsData.bytes, byteCount: nsData.length)
        buffer.packetDescriptions!.pointee.mDataByteSize = UInt32(data.count)
        buffer.packetDescriptions!.initialize(from: packetDescriptions, count: packetDescriptions.count)

        return buffer
    }


    private static func convert(withConverter: AVAudioConverter, from sourceBuffer: AVAudioBuffer, to destinationBuffer: AVAudioBuffer, error outError: NSErrorPointer) {
        // input each buffer only once
        var newBufferAvailable = true

        let inputBlock : AVAudioConverterInputBlock = {
            inNumPackets, outStatus in
            if newBufferAvailable {
                outStatus.pointee = .haveData
                newBufferAvailable = false
                return sourceBuffer
            } else {
                outStatus.pointee = .noDataNow
                return nil
            }
        }

        let status = withConverter.convert(to: destinationBuffer, error: outError, withInputFrom: inputBlock)
        print("status: \(status.rawValue)")
    }
}
