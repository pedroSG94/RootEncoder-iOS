//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public enum AmfType: UInt8 {
    case NUMBER = 0x00
    case BOOLEAN = 0x01
    case STRING = 0x02
    case OBJECT = 0x03
    case NULL = 0x05
    case UNDEFINED = 0x06
    case ECMA_ARRAY = 0x08
    case STRICT_ARRAY = 0x0A

    /**
     * Not used in RTMP
     */
    case REFERENCE = 0x07
    case DATE = 0x0B
    case LONG_STRING = 0x0C
    case OBJECT_END = 0x09
    case UNSUPPORTED = 0x0D
    case XML_DOCUMENT = 0x0F
    case TYPED_OBJECT = 0x10

    /**
     * reserved, not supported
     */
    case MOVIE_CLIP = 0x04
    case RECORD_SET = 0x0E
}