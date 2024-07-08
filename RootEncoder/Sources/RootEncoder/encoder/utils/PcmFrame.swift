//
//  File.swift
//  
//
//  Created by Pedro  on 30/6/24.
//

import Foundation
import AVFoundation


public struct PcmFrame {
    public let buffer: CMSampleBuffer
    public let ts: UInt64
    public let time: CMTime
}
