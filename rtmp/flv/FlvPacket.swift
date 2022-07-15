//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public struct FlvPacket {
    let buffer: [UInt8]
    var timeStamp: Int64
    let length: Int
    let type: FlvType

    public init(buffer: [UInt8] = [], timeStamp: Int64 = 0, length: Int = 0, type: FlvType = FlvType.AUDIO) {
        self.buffer = buffer
        self.timeStamp = timeStamp
        self.length = length
        self.type = type
    }
}