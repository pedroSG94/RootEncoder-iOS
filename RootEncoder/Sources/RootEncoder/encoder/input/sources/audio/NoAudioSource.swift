//
//  File.swift
//  RootEncoder
//
//  Created by Pedro  on 5/10/24.
//

import Foundation

public class NoAudioSource: AudioSource {
    
    private var running = false
    private var createdValue = false

    public func created() -> Bool {
        return createdValue
    }
    
    public func create(sampleRate: Int, isStereo: Bool) -> Bool {
        createdValue = true
        return true
    }
    
    public func start(calback: GetMicrophoneData) {
        running = true
    }
    
    public func stop() {
        running = false
    }
    
    public func isRunning() -> Bool {
        return running
    }
    
    public func release() {
        createdValue = false
    }
}
