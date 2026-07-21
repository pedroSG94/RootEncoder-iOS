//
//  File.swift
//  
//
//  Created by Pedro  on 16/7/24.
//

import Foundation

public protocol StreamClientListener {
    func onRequestKeyframe()
}

public extension VideoEncoder {
    func createStreamClientListener() -> StreamClientListener {
        class StreamClientHandler: StreamClientListener {
            
            private let encoder: VideoEncoder
            
            init(encoder: VideoEncoder) {
                self.encoder = encoder
            }
            
            func onRequestKeyframe() {
                encoder.forceKeyFrame()
            }
        }
        return StreamClientHandler(encoder: self)
    }
}
