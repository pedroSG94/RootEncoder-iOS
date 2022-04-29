//
// Created by Pedro  on 28/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

extension AmfString : Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    public static func ==(lhs: AmfString, rhs: AmfString) -> Bool {
        lhs === rhs
    }
}

extension UnsignedInteger {
    init(bytes: [UInt8]) {
        precondition(bytes.count <= MemoryLayout<Self>.size)
        var value: UInt64 = 0
        for byte in bytes {
            value <<= 8
            value |= UInt64(byte)
        }
        self.init(value)
    }
}

func byteArray<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
    withUnsafeBytes(of: value.bigEndian, Array.init)
}