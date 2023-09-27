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
    private var callback: GetAacData?
    private var running = false
    private var initTs: Int64 = 0
    private let thread = DispatchQueue(label: "AudioEncoder")
    
    public init(callback: GetAacData) {
        self.callback = callback
    }
    
    public func prepareAudio(inputFormat: AVAudioFormat, sampleRate: Double, channels: UInt32, bitrate: Int) -> Bool {
        outputFormat = getAACFormat(sampleRate: sampleRate, channels: channels)
        converter = AVAudioConverter(from: inputFormat, to: outputFormat!)
        converter!.bitRate = bitrate
        print("prepare audio success")
        initTs = Int64(Date().timeIntervalSince1970)
        running = true
        return true
    }
    
    public func encodeFrame(buffer: AVAudioPCMBuffer) {
        if (running) {
            let b = buffer
            thread.async {
                var error: NSError? = nil
                let aacBuffer = self.convertToAAC(buffer: b, error: &error)!
                if error != nil {
                    print("Encode error: \(error.debugDescription)")
                } else {
                    let data = Array<UInt8>(UnsafeBufferPointer<UInt8>(start: aacBuffer.data.assumingMemoryBound(to: UInt8.self), count: Int(aacBuffer.byteLength)))
                    for i in 0..<aacBuffer.packetCount {
                        let info = aacBuffer.packetDescriptions![Int(i)]
                        var mBuffer = Array<UInt8>(repeating: 0, count: Int(info.mDataByteSize))
                        mBuffer[0...mBuffer.count - 1] = data[Int(info.mStartOffset)...Int(info.mStartOffset) + Int(info.mDataByteSize - 1)]
                        let end = Int64(Date().timeIntervalSince1970)
                        let elapsedNanoSeconds = (end - self.initTs) * 1000

                        var frame = Frame()
                        frame.buffer = mBuffer
                        frame.length = UInt32(mBuffer.count)
                        frame.timeStamp = UInt64(elapsedNanoSeconds)
                        self.callback?.getAacData(frame: frame)
                    }
                }
            }
        }
    }
    
    public func stop() {
        running = false
    }
    
    private func convertToAAC(buffer: AVAudioPCMBuffer, error: inout NSError?) -> AVAudioCompressedBuffer? {
        let outBuffer = AVAudioCompressedBuffer(format: outputFormat!, packetCapacity: 8, maximumPacketSize: Int(buffer.frameLength))
        self.convert(sourceBuffer: buffer, destinationBuffer: outBuffer, error: &error)
        return outBuffer
    }
    
    private func convert(sourceBuffer: AVAudioPCMBuffer, destinationBuffer: AVAudioBuffer, error: NSErrorPointer) {
        if (running) {
            sourceBuffer.frameLength = sourceBuffer.frameCapacity
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
            converter?.convert(to: destinationBuffer, error: error, withInputFrom: inputBlock)
        }
    }
    
    private func getAACFormat(sampleRate: Double, channels: UInt32) -> AVAudioFormat? {
        var description = AudioStreamBasicDescription(mSampleRate: sampleRate, mFormatID: kAudioFormatMPEG4AAC, mFormatFlags: 0, mBytesPerPacket: 0, mFramesPerPacket: 0, mBytesPerFrame: 0, mChannelsPerFrame: channels, mBitsPerChannel: 0, mReserved: 0)
        return AVAudioFormat(streamDescription: &description)
    }
}
