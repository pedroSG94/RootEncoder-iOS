//
//  Frame.swift
//  app
//
//  Created by Mac on 04/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import common
import Foundation

public struct Frame {
    public let buffer: Array<UInt8>
    public let timeStamp: UInt64
    
    public init(buffer: Array<UInt8>, timeStamp: UInt64) {
        self.buffer = buffer
        self.timeStamp = timeStamp
    }
}
