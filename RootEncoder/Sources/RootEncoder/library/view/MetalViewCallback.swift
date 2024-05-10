//
//  MetalViewCallback.swift
//  RootEncoder
//
//  Created by Pedro  on 4/11/23.
//

import Foundation
import CoreMedia


public protocol MetalViewCallback {
    func getVideoData(pixelBuffer: CVPixelBuffer, pts: CMTime)
}
