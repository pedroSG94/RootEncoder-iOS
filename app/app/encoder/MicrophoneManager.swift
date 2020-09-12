//
//  MicrophoneManager.swift
//  app
//
//  Created by Mac on 04/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation

public class MicrophoneManager {
    
    private let thread = DispatchQueue.global()
    private let audioEngine = AVAudioEngine()
    private var startTime = 0
    private var callback: GetMicrophoneData?
    
    public init(callback: GetMicrophoneData) {
        self.callback = callback
    }
    
    private func convertToAAC(from buffer: AVAudioBuffer, error outError: inout NSError?) -> AVAudioCompressedBuffer? {
        
        let outputFormat = getAACFormat()
        let outBuffer = AVAudioCompressedBuffer(format: outputFormat!, packetCapacity: 1, maximumPacketSize: 50000)
        outBuffer.packetCount = 1
        self.convert(from: buffer, to: outBuffer, error: &outError)
        return outBuffer
    }
    
    private var converter: AVAudioConverter? = nil
    
    private func convert(from sourceBuffer: AVAudioBuffer, to destinationBuffer: AVAudioBuffer, error outError: inout NSError?) {
        
        //init converter
        let inputFormat = sourceBuffer.format
        let outputFormat = destinationBuffer.format
        if converter == nil {
            converter = AVAudioConverter(from: inputFormat, to: outputFormat)
            converter!.bitRate = 64000
        }
        let inputBlock : AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = AVAudioConverterInputStatus.haveData
            return sourceBuffer
        }
        
        _ = converter!.convert(to: destinationBuffer, error: &outError, withInputFrom: inputBlock)
    }
    
    private func getAACFormat() -> AVAudioFormat? {
        var description = AudioStreamBasicDescription(mSampleRate: 44100, mFormatID: kAudioFormatMPEG4AAC, mFormatFlags: 0, mBytesPerPacket: 0, mFramesPerPacket: 0, mBytesPerFrame: 0, mChannelsPerFrame: 1, mBitsPerChannel: 0, mReserved: 0)
        return AVAudioFormat(streamDescription: &description)
    }
    
    public func start() {
        let inputNode = self.audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        if (inputFormat.channelCount == 0) {
            print("input format error")
        }
        
        let start = Date().millisecondsSince1970

        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { buffer, time in
            self.thread.async {
                var error: NSError? = nil
                let aacBuffer = AudioBufferConverter.convertToAAC(from: buffer, error: &error)!
                if error != nil {
                    print("Encode error: \(error.debugDescription)")
                } else {
                    let data = Array<UInt8>(UnsafeBufferPointer<UInt8>(start: aacBuffer.data.assumingMemoryBound(to: UInt8.self), count: Int(aacBuffer.byteLength)))
                    for i in 0..<aacBuffer.packetCount {
                        let info = aacBuffer.packetDescriptions![Int(i)]
                        var mBuffer = Array<UInt8>(repeating: 0, count: Int(info.mDataByteSize))
                        mBuffer[0...mBuffer.count - 1] = data[Int(info.mStartOffset)...Int(info.mStartOffset) + Int(info.mDataByteSize - 1)]
                        let end = Date().millisecondsSince1970
                        let elapsed_nanoseconds = (end - start) * 1000000
                    
                        var frame = Frame()
                        frame.buffer = mBuffer
                        frame.length = UInt32(mBuffer.count)
                        frame.timeStamp = UInt64(elapsed_nanoseconds)
                        self.callback?.getPcmData(frame: frame)
                    }
                }
            }
        }

        self.audioEngine.prepare()
        do {
            try self.audioEngine.start()
        } catch {
            print(error)
        }
    }
    
    public func stop() {
        self.audioEngine.stop()
    }
}
