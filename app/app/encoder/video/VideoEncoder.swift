//
//  VideoEncoder.swift
//  app
//
//  Created by Pedro  on 16/5/21.
//  Copyright © 2021 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation

public class VideoEncoder {
    
    private let callback: GetH264Data
    
    public init(callback: GetH264Data) {
        self.callback = callback
    }
    
    public func prepareVideo() {
        
    }
    
    public func encodeFrame(buffer: CMSampleBuffer, initTs: Int64) {
        
        
        let end = Date().millisecondsSince1970
        let elapsedNanoSeconds = (end - initTs) * 1000000
        var frame = Frame()
        frame.timeStamp = UInt64(elapsedNanoSeconds)
        callback.getH264Data(frame: frame)
    }
}
