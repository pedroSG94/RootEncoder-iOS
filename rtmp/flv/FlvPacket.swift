//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public struct FlvPacket {
    let buffer: [UInt8] = []
    var timeStamp: Int64 = 0
    let length: Int = 0
    let type: FlvType = FlvType.AUDIO
}