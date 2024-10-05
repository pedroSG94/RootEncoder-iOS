//
//  File.swift
//  RootEncoder
//
//  Created by Pedro  on 5/10/24.
//

import Foundation

public class NoVideoSource: VideoSource {
    
    private var running = false
    private var createdValue = false

    public func created() -> Bool {
        return createdValue
    }
    
    public func create(width: Int, height: Int, fps: Int, rotation: Int) -> Bool {
        createdValue = true
        return true
    }
    
    public func start(metalInterface: MetalInterface) {
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
