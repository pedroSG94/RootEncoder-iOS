//
//  File.swift
//  
//
//  Created by Pedro  on 30/8/24.
//

import Foundation

public class SensorManager {
    
    private var running = false
    
    public func start(callback: @escaping (Int) -> Void) {
        running = true
        DispatchQueue(label: "SensorManager").async {
            while self.running {
                DispatchQueue.main.sync {
                    let orientation = CameraHelper.getCameraOrientation()
                    callback(orientation)
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
    
    public func stop() {
        running = false
    }
}
