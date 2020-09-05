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
        print("start -1")
        let inputNode = self.audioEngine.inputNode
        print("start 0")
        let inputFormat = inputNode.inputFormat(forBus: 0)
        if (inputFormat.channelCount == 0) {
            print("input format error")
        }
        print("start 1")
        let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 44100.0, channels: 2, interleaved: true)
//        let formatConverter = AVAudioConverter(from: inputFormat, to: recordingFormat!)
        print("start 2")
        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(2048), format: inputFormat) { buffer, time in
            print("start 5")
            self.thread.async {
                let error: NSError? = nil
                let capacity = AVAudioFrameCount(recordingFormat!.sampleRate * 2)
                let pcmBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat!, frameCapacity: capacity)

//                let inputBlock: AVAudioConverterInputBlock = {inNumPackets, outStatus in
//                    outStatus.pointee = AVAudioConverterInputStatus.haveData
//                    return buffer
//                }

//                formatConverter?.convert(to: pcmBuffer!, error: &error, withInputFrom: inputBlock)
                if error != nil {
                    print(error!.localizedDescription)
                } else if let channelData = pcmBuffer!.int16ChannelData {
                    let channelDataPointer = channelData.pointee
                    let channelData = stride(from: 0, to: Int(pcmBuffer!.frameLength), by: buffer.stride).map { channelDataPointer[$0] }
                    var frame = Frame()
                    //TODO change to Array<UInt8>
                    frame.buffer = byteArray(from: channelData)
                    frame.length = channelData.count
                    frame.timeStamp = Int64(time.hostTime)
                    self.callback?.getPcmData(frame: frame)
                }
            }
        }
        print("start 3")
        self.audioEngine.prepare()
        print("start 4")
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
