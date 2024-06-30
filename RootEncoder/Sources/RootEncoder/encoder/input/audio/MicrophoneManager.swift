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
    
    private let thread = DispatchQueue(label: "MicrophoneManager")
    private let audioEngine = AVAudioEngine()
    private var inputFormat: AVAudioFormat?
    private var muted = false
    
    private var callback: GetMicrophoneData?
    
    public init(callback: GetMicrophoneData) {
        self.callback = callback
    }

    public func createMicrophone() {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        self.inputFormat = inputFormat
        if (inputFormat.channelCount == 0) {
            print("input format error")
        }
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { buffer, time in
            self.thread.async {
                let ts = Date().millisecondsSince1970
                self.callback?.getPcmData(frame: PcmFrame(buffer: buffer.mute(enabled: !self.muted), ts: ts), time: time)
            }
        }
        audioEngine.prepare()
    }
    
    public func getInputFormat() -> AVAudioFormat {
        inputFormat!
    }
    
    public func start() {
        do {
            try audioEngine.start()
        } catch let error {
            print(error)
        }
    }
    
    public func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
    
    public func isMuted() -> Bool {
        return muted
    }
    
    public func mute() {
        muted = true
    }
    
    public func unmute() {
        muted = false
    }
}
