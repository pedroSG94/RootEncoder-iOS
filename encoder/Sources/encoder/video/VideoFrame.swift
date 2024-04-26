//
//  VideoFrame.swift
//  encoder
//
//  Created by Pedro  on 4/11/23.
//

import Foundation
import CoreMedia

public struct VideoFrame {

    let pixelBuffer: CVPixelBuffer
    let pts: CMTime
    
    public init(pixelBuffer: CVPixelBuffer, pts: CMTime) {
        self.pixelBuffer = pixelBuffer
        self.pts = pts
    }

}
