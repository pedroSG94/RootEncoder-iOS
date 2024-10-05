//
//  File.swift
//  RootEncoder
//
//  Created by Pedro  on 5/10/24.
//

import Foundation

public class MicrophoneSource: AudioSource, GetMicrophoneData {
    
    private lazy var microphone: MicrophoneManager = {
        MicrophoneManager(callback: self)
    }()
    private var callback: GetMicrophoneData? = nil
    private var running = false
    
    public init() { }
    
    public func create(sampleRate: Int, isStereo: Bool) -> Bool {
        return microphone.createMicrophone()
    }
    
    public func start(calback: GetMicrophoneData) {
        self.callback = calback
        running = true
        microphone.start()
    }
    
    public func stop() {
        running = false
        microphone.stop()
    }
    
    public func isRunning() -> Bool {
        return running
    }
    
    public func release() { }
    
    public func getPcmData(frame: PcmFrame) {
        callback?.getPcmData(frame: frame)
    }
    
    public func isMuted() -> Bool {
        return microphone.isMuted()
    }
    
    public func mute() {
        microphone.mute()
    }
    
    public func unmute() {
        microphone.unmute()
    }
}
