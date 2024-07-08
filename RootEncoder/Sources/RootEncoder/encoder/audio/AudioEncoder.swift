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
    private var bitrate = 128 * 1000
    private var ringBuffer: AudioRingBuffer? = nil
    private var audioTime: AudioTime = AudioTime()
    
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
        running = true
        syncQueue.clear()
        thread.async {
            while (self.running) {
                let pcmFrame = self.syncQueue.dequeue()
                if let pcmFrame = pcmFrame {
                    if self.inputFormat == nil {
                        guard let description = pcmFrame.buffer.formatDescription else {
                            continue
                        }
                        let format = AVAudioFormat(cmAudioFormatDescription: description)
                        self.inputFormat = format
                        self.ringBuffer = AudioRingBuffer(format)
                        self.audioTime.reset()
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
                    guard let outputFormat = self.outputFormat else { continue }
                    if !self.audioTime.hasAnchor {
                        self.audioTime.anchor(pcmFrame.buffer.presentationTimeStamp, sampleRate: outputFormat.sampleRate)
                    }
                    self.ringBuffer?.append(pcmFrame.buffer)
                    if self.codec == AudioCodec.AAC {
                        self.convertAAC(error: &error)
                    } else if self.codec == AudioCodec.G711 {
                        self.convertG711(error: &error)
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
        audioTime.reset()
    }
    
    private func convertAAC(error: NSErrorPointer) {
        if (running) {
            guard let inputFormat = inputFormat, let outputFormat = outputFormat else { return }
            let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: 1024 * 4)
            guard let inputBuffer = inputBuffer else { return }
            
            let outputBuffer = AVAudioCompressedBuffer(format: outputFormat, packetCapacity: 1, maximumPacketSize: 1024 * Int(outputFormat.channelCount))
            convert(inputBuffer: inputBuffer, outputBuffer: outputBuffer)
        }
    }
    
    private func convertG711(error: NSErrorPointer) {
        if (running) {
            guard let inputFormat = inputFormat, let outputFormat = outputFormat else { return }
            let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: 1024 * 4)
            guard let inputBuffer = inputBuffer else { return }
            
            let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: AVAudioFrameCount(outputFormat.sampleRate) * inputBuffer.frameLength / AVAudioFrameCount(inputBuffer.format.sampleRate))!
            outputBuffer.frameLength = outputBuffer.frameCapacity
            convert(inputBuffer: inputBuffer, outputBuffer: outputBuffer)
        }
    }
    
    private func convert(inputBuffer: AVAudioPCMBuffer, outputBuffer: AVAudioBuffer) {
        guard let inputFormat = inputFormat, let outputFormat = outputFormat, let ringBuffer = ringBuffer else {
            return
        }
        
        
        var status: AVAudioConverterOutputStatus? = .endOfStream
        repeat {
            status = converter?.convert(to: outputBuffer, error: nil) { inNumberFrames, status in
                if inNumberFrames <= ringBuffer.counts {
                    _ = ringBuffer.render(inNumberFrames, ioData: inputBuffer.mutableAudioBufferList)
                    inputBuffer.frameLength = inNumberFrames
                    status.pointee = .haveData
                    return inputBuffer
                } else {
                    status.pointee = .noDataNow
                    return nil
                }
            }
            switch status {
            case .haveData:
                let data: Array<UInt8>
                switch outputBuffer {
                case let outputBuffer as AVAudioCompressedBuffer:
                    data = Array<UInt8>(UnsafeBufferPointer<UInt8>(start: outputBuffer.data.assumingMemoryBound(to: UInt8.self), count: Int(outputBuffer.byteLength)))
                case let outputBuffer as AVAudioPCMBuffer:
                    data = outputBuffer.audioBufferToBytes()
                default:
                    continue
                }
                
                let ts = UInt64(self.audioTime.at.makeTime().seconds * 1000000)
                if self.initTs == 0 {
                    self.initTs = ts
                }
                let elapsedMicroSeconds = ts - self.initTs
                self.callback?.getAacData(frame: Frame(buffer: data, length: UInt32(data.count), timeStamp: elapsedMicroSeconds))
                self.audioTime.advanced(1024)
            case .error:
                print("error")
            default:
                break
            }
        } while(status == .haveData)
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
