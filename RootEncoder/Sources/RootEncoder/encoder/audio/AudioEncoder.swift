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
    private var outputFormat: AVAudioFormat? = nil
    private var callback: GetAacData?
    private var running = false
    private var initTs: UInt64 = 0
    private let thread = DispatchQueue(label: "AudioEncoder")
    private let syncQueue = SynchronizedQueue<PcmFrame>(label: "AudioEncodeQueue", size: 60)
    private var codec = AudioCodec.AAC
    private var inputFormat: AVAudioFormat? = nil
    private var bitrate = 64 * 1000
    
    public init(callback: GetAacData) {
        self.callback = callback
    }
    
    public func setCodec(codec: AudioCodec) {
        self.codec = codec
    }
    
    public func prepareAudio(sampleRate: Double, channels: UInt32, bitrate: Int) -> Bool {
        if (codec == AudioCodec.G711 && (sampleRate != 8000 || channels != 1)) {
            print("G711 only support samplerate 8000 and mono channel")
            return false
        }
        let format: AVAudioFormat? = if codec == AudioCodec.AAC {
            getAACFormat(sampleRate: sampleRate, channels: channels)
        } else if codec == AudioCodec.G711 {
            getG711AFormat(sampleRate: sampleRate, channels: channels)
        } else {
            nil
        }
        guard let outputFormat = format else {
            return false
        }
        self.outputFormat = outputFormat
        self.bitrate = bitrate
        print("prepare audio success")
        return true
    }
    
    public func encodeFrame(frame: PcmFrame) {
        if (running) {
            let _ = syncQueue.enqueue(frame)
        }
    }
    
    public func start() {
        self.initTs = UInt64(Date().millisecondsSince1970 * 1000)
        running = true
        syncQueue.clear()
        thread.async {
            while (self.running) {
                let pcmFrame = self.syncQueue.dequeue()
                if let pcmFrame = pcmFrame {
                    let ts = UInt64(pcmFrame.ts * 1000)
                    if self.inputFormat == nil {
                        self.inputFormat = pcmFrame.buffer.format
                    }
                    if self.converter == nil {
                        if let inputFormat = self.inputFormat, let outputFormat = self.outputFormat {
                            guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
                                continue
                            }
                            self.converter = converter
                            converter.bitRate = self.bitrate
                        }
                    }
                    var error: NSError? = nil
                    if self.codec == AudioCodec.AAC {
                        guard let aacBuffer = self.convertAAC(inputBuffer: pcmFrame.buffer, error: &error) else {
                            continue
                        }
                        if error != nil {
                            print("Encode error: \(error.debugDescription)")
                        } else {
                            let data = Array<UInt8>(UnsafeBufferPointer<UInt8>(start: aacBuffer.data.assumingMemoryBound(to: UInt8.self), count: Int(aacBuffer.byteLength)))
                            let elapsedMicroSeconds = ts - self.initTs
                            self.callback?.getAacData(frame: Frame(buffer: data, length: UInt32(data.count), timeStamp: elapsedMicroSeconds))
                        }
                    } else if self.codec == AudioCodec.G711 {
                        guard let g711Buffer = self.convertG711(inputBuffer: pcmFrame.buffer, error: &error) else {
                            continue
                        }
                        if error != nil {
                            print("Encode error: \(error.debugDescription)")
                        } else {
                            let data = g711Buffer.audioBufferToBytes()
                            let elapsedMicroSeconds = ts - self.initTs
                            self.callback?.getAacData(frame: Frame(buffer: data, length: UInt32(data.count), timeStamp: elapsedMicroSeconds))
                        }
                    }
                }
            }
        }
    }
    
    public func stop() {
        running = false
        converter = nil
        outputFormat = nil
        initTs = 0
        syncQueue.clear()
    }
    
    private func convertAAC(inputBuffer: AVAudioPCMBuffer, error: NSErrorPointer) -> AVAudioCompressedBuffer? {
        if (running) {
            guard let outputFormat = outputFormat else {
                return nil
            }
            let outputBuffer = AVAudioCompressedBuffer(format: outputFormat, packetCapacity: 1, maximumPacketSize: 1024 * Int(outputFormat.channelCount))
            
            converter?.convert(to: outputBuffer, error: nil) { _, outStatus in
                outStatus.pointee = .haveData
                return inputBuffer
            }
            return outputBuffer
        } else {
            return nil
        }
    }
    
    private func convertG711(inputBuffer: AVAudioPCMBuffer, error: NSErrorPointer) -> AVAudioPCMBuffer? {
        if (running) {
            guard let outputFormat = outputFormat else {
                return nil
            }
            let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: AVAudioFrameCount(outputFormat.sampleRate) * inputBuffer.frameLength / AVAudioFrameCount(inputBuffer.format.sampleRate))!
            outputBuffer.frameLength = outputBuffer.frameCapacity
            
            converter?.convert(to: outputBuffer, error: nil) { _, outStatus in
                outStatus.pointee = .haveData
                return inputBuffer
            }
            return outputBuffer
        } else {
            return nil
        }
    }
    
    private func getAACFormat(sampleRate: Double, channels: UInt32) -> AVAudioFormat? {
        var description = AudioStreamBasicDescription(mSampleRate: sampleRate,
                                                      mFormatID: kAudioFormatMPEG4AAC,
                                                      mFormatFlags: UInt32(MPEG4ObjectID.AAC_LC.rawValue),
                                                      mBytesPerPacket: 0,
                                                      mFramesPerPacket: 0,
                                                      mBytesPerFrame: 0,
                                                      mChannelsPerFrame: channels,
                                                      mBitsPerChannel: 0,
                                                      mReserved: 0)
        return AVAudioFormat(streamDescription: &description)
    }
    
    private func getG711AFormat(sampleRate: Double, channels: UInt32) -> AVAudioFormat? {
        var description = AudioStreamBasicDescription(mSampleRate: sampleRate,
                                                      mFormatID: kAudioFormatALaw,
                                                      mFormatFlags: AudioFormatFlags(kAudioFormatALaw),
                                                      mBytesPerPacket: 1,
                                                      mFramesPerPacket: 1,
                                                      mBytesPerFrame: 1,
                                                      mChannelsPerFrame: channels,
                                                      mBitsPerChannel: 8,
                                                      mReserved: 0)
        return AVAudioFormat(streamDescription: &description)
    }
}
