//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public enum ChunkStreamId: UInt8 {
    case PROTOCOL_CONTROL = 0x02
    case OVER_CONNECTION = 0x03
    case OVER_CONNECTION2 = 0x04
    case OVER_STREAM = 0x05
    case VIDEO = 0x06
    case AUDIO = 0x07
}