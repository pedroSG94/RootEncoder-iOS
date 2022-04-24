//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public enum Amf3Type: UInt8 {
    case UNDEFINED = 0x00
    case NULL = 0x01
    case TRUE = 0x02
    case FALSE = 0x03
    case INTEGER = 0x04
    case DOUBLE = 0x05
    case STRING = 0x06
    case XML_DOC = 0x07
    case DATE = 0x08
    case ARRAY = 0x09
    case OBJECT = 0x0A
    case XML = 0x0B
    case BYTE_ARRAY = 0x0C
    case VECTOR_INT = 0x0D
    case VECTOR_UINT = 0x0E
    case VECTOR_DOUBLE = 0x0F
    case VECTOR_OBJECT = 0x10
    case DICTIONARY = 0x11
}