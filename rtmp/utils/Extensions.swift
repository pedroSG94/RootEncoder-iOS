//
// Created by Pedro  on 28/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

extension Array {
    public mutating func takeFirst(n: Int) -> Array {
        let a = self.prefix(upTo: n)
        removeFirst(n)
        return Array(a)
    }
}

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

func byteArrayLittleEndian<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
    withUnsafeBytes(of: value.littleEndian, Array.init)
}

extension Int {

    public func toUInt8Array() -> [UInt8] {
        let bytes = byteArray(from: self)
        let array = [UInt8](arrayLiteral: bytes[0])
        return array
    }

    public func toUInt16Array() -> [UInt8] {
        let bytes = byteArray(from: self)
        let array = [UInt8](arrayLiteral: bytes[0], bytes[1])
        return array
    }

    public func toUInt24Array() -> [UInt8] {
        let bytes = byteArray(from: self)
        let array = [UInt8](arrayLiteral: bytes[0], bytes[1], bytes[2])
        return array
    }

    public func toUInt32Array() -> [UInt8] {
        let bytes = byteArray(from: self)
        let array = [UInt8](arrayLiteral: bytes[0], bytes[1], bytes[2], bytes[3])
        return array
    }

    public func toUInt8LittleEndianArray() -> [UInt8] {
        let bytes = byteArrayLittleEndian(from: self)
        let array = [UInt8](arrayLiteral: bytes[0])
        return array
    }

    public func toUInt16LittleEndianArray() -> [UInt8] {
        let bytes = byteArrayLittleEndian(from: self)
        let array = [UInt8](arrayLiteral: bytes[0], bytes[1])
        return array
    }

    public func toUInt24LittleEndianArray() -> [UInt8] {
        let bytes = byteArrayLittleEndian(from: self)
        let array = [UInt8](arrayLiteral: bytes[0], bytes[1], bytes[2])
        return array
    }

    public func toUInt32LittleEndianArray() -> [UInt8] {
        let bytes = byteArrayLittleEndian(from: self)
        let array = [UInt8](arrayLiteral: bytes[0], bytes[1], bytes[2], bytes[3])
        return array
    }
}

func toUInt32(array: [UInt8]) -> UInt32 {
    let data = Data(_: array)
    let value: UInt32 = data.withUnsafeBytes { bytes in
        bytes.load(as: UInt32.self)
    }
    return value
}

func toInt(array: [UInt8]) -> Int {
    let data = Data(_: array)
    let value: Int = data.withUnsafeBytes { bytes in
        bytes.load(as: Int.self)
    }
    return value
}

func toUInt16(array: [UInt8]) -> UInt16 {
    let data = Data(_: array)
    let value: UInt16 = data.withUnsafeBytes { bytes in
        bytes.load(as: UInt16.self)
    }
    return value
}