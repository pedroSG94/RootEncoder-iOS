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
                        if let formatDescription = pcmFrame.buffer.formatDescription, self.inputFormat?.formatDescription != formatDescription {
                            self.inputFormat = AVAudioFormat(cmAudioFormatDescription: formatDescription)
                        }
                    }
                    if self.converter == nil {
                        guard let converter = AVAudioConverter(from: self.inputFormat!, to: self.outputFormat!) else {
                            continue
                        }
                        self.converter = converter
                        converter.bitRate = self.bitrate
                    }
                    if self.initTs == 0 { self.initTs = ts }
                    var error: NSError? = nil
                    if self.codec == AudioCodec.AAC {
                        guard let aacBuffer = self.convertAAC(buffer: pcmFrame.buffer, error: &error) else {
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
                        guard let g711Buffer = self.convertG711(buffer: pcmFrame.buffer, error: &error) else {
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
    
    private func convertAAC(buffer: CMSampleBuffer, error: NSErrorPointer) -> AVAudioCompressedBuffer? {
        if (running) {
            guard let inputFormat = inputFormat, let outputFormat = outputFormat, let blockBuffer = CMSampleBufferGetDataBuffer(buffer) else {
                return nil
            }
            let outputBuffer = AVAudioCompressedBuffer(format: outputFormat, packetCapacity: 1, maximumPacketSize: 1024 * Int(outputFormat.channelCount))
            
            var length = 0
            var dataPointer: UnsafeMutablePointer<Int8>?
            
            CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)
            
            let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: AVAudioFrameCount(inputFormat.sampleRate))
            inputBuffer?.frameLength = AVAudioFrameCount(length) / inputFormat.streamDescription.pointee.mBytesPerFrame
            memcpy(inputBuffer?.int16ChannelData?[0], dataPointer, length)
            
            converter?.convert(to: outputBuffer, error: nil) { _, outStatus in
                outStatus.pointee = .haveData
                return inputBuffer
            }
            return outputBuffer
        } else {
            return nil
        }
    }
    
    private func convertG711(buffer: CMSampleBuffer, error: NSErrorPointer) -> AVAudioPCMBuffer? {
        if (running) {
            guard let inputFormat = inputFormat, let outputFormat = outputFormat, let blockBuffer = CMSampleBufferGetDataBuffer(buffer) else {
                return nil
            }
            let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: AVAudioFrameCount(inputFormat.sampleRate))
            guard let outputBuffer = outputBuffer else {
                return nil
            }
            outputBuffer.frameLength = outputBuffer.frameCapacity
            
            var length = 0
            var dataPointer: UnsafeMutablePointer<Int8>?
            
            CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)
            
            let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: AVAudioFrameCount(inputFormat.sampleRate))
            inputBuffer?.frameLength = AVAudioFrameCount(length) / inputFormat.streamDescription.pointee.mBytesPerFrame
            memcpy(inputBuffer?.int16ChannelData?[0], dataPointer, length)
            
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
