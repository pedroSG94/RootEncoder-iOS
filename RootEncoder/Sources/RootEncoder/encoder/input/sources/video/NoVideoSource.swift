//
//  File.swift
//  RootEncoder
//
//  Created by Pedro  on 5/10/24.
//

import Foundation

public class NoVideoSource: VideoSource {
    
    private var running = false
    
    public func create(width: Int, height: Int, fps: Int, rotation: Int) -> Bool {
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
        
    }
}
