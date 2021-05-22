//  AudioEncoder.swift
//  app
//
//  Created by Mac on 07/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation

public class AudioEncoder {
    
    private var converter: AVAudioConverter? = nil
    private var outputFormat: AVAudioFormat?
    private var inputFormat: AVAudioFormat?
    private var callback: GetAacData?
    private var running = false
    
    public init(inputFormat: AVAudioFormat, callback: GetAacData) {
        self.inputFormat = inputFormat
        self.callback = callback
    }
    
    public func prepareAudio(sampleRate: Double, channels: UInt32, bitrate: Int) {
        outputFormat = self.getAACFormat(sampleRate: sampleRate, channels: channels)
        converter = AVAudioConverter(from: inputFormat!, to: outputFormat!)
        converter!.bitRate = bitrate
        print("prepare audio success")
        running = true
    }
    
    public func encodeFrame(from buffer: AVAudioBuffer, initTS: Int64) {
        if (running) {
            var error: NSError? = nil
            let aacBuffer = convertToAAC(from: buffer, error: &error)!
            if error != nil {
                print("Encode error: \(error.debugDescription)")
            } else {
                let data = Array<UInt8>(UnsafeBufferPointer<UInt8>(start: aacBuffer.data.assumingMemoryBound(to: UInt8.self), count: Int(aacBuffer.byteLength)))
                for i in 0..<aacBuffer.packetCount {
                    let info = aacBuffer.packetDescriptions![Int(i)]
                    var mBuffer = Array<UInt8>(repeating: 0, count: Int(info.mDataByteSize))
                    mBuffer[0...mBuffer.count - 1] = data[Int(info.mStartOffset)...Int(info.mStartOffset) + Int(info.mDataByteSize - 1)]
                    let end = Date().millisecondsSince1970
                    let elapsedNanoSeconds = (end - initTS) * 1000000
            
                    var frame = Frame()
                    frame.buffer = mBuffer
                    frame.length = UInt32(mBuffer.count)
                    frame.timeStamp = UInt64(elapsedNanoSeconds)
                    self.callback?.getAacData(frame: frame)
                }
            }
        }
    }
    
    public func stop() {
        running = false
    }
    
    private func convertToAAC(from buffer: AVAudioBuffer, error outError: inout NSError?) -> AVAudioCompressedBuffer? {
        let outBuffer = AVAudioCompressedBuffer(format: outputFormat!, packetCapacity: 8, maximumPacketSize: 768)
        self.convert(from: buffer, to: outBuffer, error: &outError)
        return outBuffer
    }
    
    private func convert(from sourceBuffer: AVAudioBuffer, to destinationBuffer: AVAudioBuffer, error outError: NSErrorPointer) {
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

        _ = converter!.convert(to: destinationBuffer, error: outError, withInputFrom: inputBlock)
    }
    
    private func getAACFormat(sampleRate: Double, channels: UInt32) -> AVAudioFormat? {
        var description = AudioStreamBasicDescription(mSampleRate: sampleRate, mFormatID: kAudioFormatMPEG4AAC, mFormatFlags: 0, mBytesPerPacket: 0, mFramesPerPacket: 0, mBytesPerFrame: 0, mChannelsPerFrame: channels, mBitsPerChannel: 0, mReserved: 0)
        return AVAudioFormat(streamDescription: &description)
    }
}
