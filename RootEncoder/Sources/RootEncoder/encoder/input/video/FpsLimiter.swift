//
//  File.swift
//  
//
//  Created by Pedro  on 23/7/24.
//

import Foundation

public class FpsLimiter {
    
    private var startTs = Date().millisecondsSince1970
    private var ratioF: Int64 = 1000 / 30
    private var ratio: Int64 = 1000 / 30
    private var frameStartTs: Int64 = 0
    private var configured = false
    
    public func setFps(fps: Int) {
        if fps <= 0 {
            configured = false
            return
        } else {
            configured = true
        }
        startTs = Date().millisecondsSince1970
        ratioF = 1000 / Int64(fps)
        ratio = 1000 / Int64(fps)
    }
    
    public func limitFps() -> Bool {
        if !configured {
            return false
        }
        let lastFrameTimestamp = Date().millisecondsSince1970 - startTs
        if ratio < lastFrameTimestamp {
            ratio += ratioF
            return false
        }
        return true
    }
    
    public func setFrameStartTs() {
        frameStartTs = Date().millisecondsSince1970
    }
    
    public func getSleepTime() -> Int64 {
        return max(0, ratioF - (Date().millisecondsSince1970 - frameStartTs))
    }
}
