//
//  Frame.swift
//  app
//
//  Created by Mac on 04/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import Foundation

public struct RtspFrame {
    
    public var buffer: Array<UInt8>?
    public var length: UInt32?
    public var timeStamp: UInt64?
    public var flag: Int? = 1
    
    public init(buffer: Array<UInt8>? = nil, length: UInt32? = nil, timeStamp: UInt64? = nil, flag: Int? = nil) {
        self.buffer = buffer
        self.length = length
        self.timeStamp = timeStamp
        self.flag = flag
    }
}
