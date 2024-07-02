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
    
    public init(callback: GetAacData) {
        self.callback = callback
    }
    
    public func setCodec(codec: AudioCodec) {
        self.codec = codec
    }
    
    public func prepareAudio(inputFormat: AVAudioFormat, sampleRate: Double, channels: UInt32, bitrate: Int) -> Bool {
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
        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            return false
        }
        converter.bitRate = bitrate
        self.outputFormat = outputFormat
        self.converter = converter
        print("prepare audio success")
        return true
    }
    
    public func encodeFrame(frame: PcmFrame) {
        if (running) {
            let _ = syncQueue.enqueue(frame)
        }
    }
    
    public func start() {
        initTs = UInt64(Date().millisecondsSince1970)
        running = true
        syncQueue.clear()
        thread.async {
            while (self.running) {
                let pcmFrame = self.syncQueue.dequeue()
                if let pcmFrame = pcmFrame {
                    var error: NSError? = nil
                    if self.codec == AudioCodec.AAC {
                        guard let aacBuffer = self.convertToAAC(buffer: pcmFrame.buffer, error: &error) else {
                            continue
                        }
                        if error != nil {
                            print("Encode error: \(error.debugDescription)")
                        } else {
                            let data = Array<UInt8>(UnsafeBufferPointer<UInt8>(start: aacBuffer.data.assumingMemoryBound(to: UInt8.self), count: Int(aacBuffer.byteLength)))
                            let elapsedNanoSeconds = (pcmFrame.ts - self.initTs) * 1000
                            var frame = Frame()
                            frame.buffer = data
                            frame.length = UInt32(data.count)
                            frame.timeStamp = elapsedNanoSeconds
                            self.callback?.getAacData(frame: frame)
                        }
                    } else if self.codec == AudioCodec.G711 {
                        guard let g711Buffer = self.convertToG711(buffer: pcmFrame.buffer, error: &error) else {
                            continue
                        }
                        if error != nil {
                            print("Encode error: \(error.debugDescription)")
                        } else {
                            let data = g711Buffer.audioBufferToBytes()
                            let elapsedNanoSeconds = (pcmFrame.ts - self.initTs) * 1000

                            var frame = Frame()
                            frame.buffer = data
                            frame.length = UInt32(data.count)
                            frame.timeStamp = elapsedNanoSeconds
                            self.callback?.getAacData(frame: frame)
                            
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
    
    private func convertToAAC(buffer: AVAudioPCMBuffer, error: inout NSError?) -> AVAudioCompressedBuffer? {
        guard let outputFormat = outputFormat else {
            return nil
        }
        let outBuffer = AVAudioCompressedBuffer(format: outputFormat, packetCapacity: 1, maximumPacketSize: 1024 * Int(outputFormat.channelCount))
        self.convert(sourceBuffer: buffer, destinationBuffer: outBuffer, error: &error)
        return outBuffer
    }
    
    private func convertToG711(buffer: AVAudioPCMBuffer, error: inout NSError?) -> AVAudioPCMBuffer? {
        guard let outputFormat = outputFormat else {
            return nil
        }
        let outBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: AVAudioFrameCount(outputFormat.sampleRate) * buffer.frameLength / AVAudioFrameCount(buffer.format.sampleRate))!
        self.convert(sourceBuffer: buffer, destinationBuffer: outBuffer, error: &error)
        return outBuffer
    }
    
    private func convert(sourceBuffer: AVAudioPCMBuffer, destinationBuffer: AVAudioBuffer, error: NSErrorPointer) {
        if (running) {
            converter?.convert(to: destinationBuffer, error: error) { _, inputStatus in
                inputStatus.pointee = .haveData
                return sourceBuffer
            }
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
