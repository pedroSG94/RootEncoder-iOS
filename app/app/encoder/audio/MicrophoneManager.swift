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
    private var inputNode: AVAudioInputNode?
    private var inputFormat: AVAudioFormat?
    
    private var callback: GetMicrophoneData?
    
    public init(callback: GetMicrophoneData) {
        self.callback = callback
    }

    public func createMicrophone() {
        inputNode = audioEngine.inputNode
        inputFormat = inputNode!.outputFormat(forBus: 0)
        if (inputFormat!.channelCount == 0) {
            print("input format error")
        }
        inputNode?.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { buffer, time in
            self.thread.async {
                self.callback?.getPcmData(buffer: buffer)
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
}
