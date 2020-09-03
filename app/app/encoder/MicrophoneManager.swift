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
    private var callback: GetMicrophoneData?
    
    public init(callback: GetMicrophoneData) {
        self.callback = callback
    }
    
    public func start() {
        let inputNode = self.audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 44100, channels: 2, interleaved: true)
        let formatConverter = AVAudioConverter(from: inputFormat, to: recordingFormat!)
        
        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(4096), format: inputFormat) { buffer, time in
            self.thread.async {
                var error: NSError? = nil
                let capacity = AVAudioFrameCount(recordingFormat!.sampleRate * 2)
                let pcmBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat!, frameCapacity: capacity)
                
                let inputBlock: AVAudioConverterInputBlock = {inNumPackets, outStatus in
                    outStatus.pointee = AVAudioConverterInputStatus.haveData
                    return buffer
                }
                
                formatConverter?.convert(to: pcmBuffer!, error: &error, withInputFrom: inputBlock)
                if error != nil {
                    print(error!.localizedDescription)
                } else if let channelData = pcmBuffer!.int16ChannelData {
                    let channelDataPointer = channelData.pointee
                    let channelData = stride(from: 0, to: Int(pcmBuffer!.frameLength), by: buffer.stride).map { channelDataPointer[$0] }
                    var frame = Frame()
                    //TODO change to Array<UInt8>
                    //                frame.buffer = channelData
                    frame.length = channelData.count
                    frame.timeStamp = Int64(time.hostTime)
                    self.callback?.getPcmData(frame: frame)
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
