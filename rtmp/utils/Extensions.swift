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

extension String {
    subscript (range: Range<Int>) -> Substring {
        let startIndex = self.index(self.startIndex, offsetBy: range.startIndex)
        let stopIndex = self.index(self.startIndex, offsetBy: range.startIndex + range.count)
        return self[startIndex..<stopIndex]
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
        let uInt = UInt32(self)
        var bigEndian = uInt.bigEndian
        let count = MemoryLayout<UInt32>.size
        let byteArray = withUnsafePointer(to: &bigEndian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        return [UInt8](arrayLiteral: byteArray[3])
    }

    public func toUInt16Array() -> [UInt8] {
        let uInt = UInt32(self)
        var bigEndian = uInt.bigEndian
        let count = MemoryLayout<UInt32>.size
        let byteArray = withUnsafePointer(to: &bigEndian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        return [UInt8](arrayLiteral: byteArray[2], byteArray[3])
    }

    public func toUInt24Array() -> [UInt8] {
        let uInt = UInt32(self)
        var bigEndian = uInt.bigEndian
        let count = MemoryLayout<UInt32>.size
        let byteArray = withUnsafePointer(to: &bigEndian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        return [UInt8](arrayLiteral: byteArray[1], byteArray[2], byteArray[3])
    }

    public func toUInt32Array() -> [UInt8] {
        let uInt = UInt32(self)
        var bigEndian = uInt.bigEndian
        let count = MemoryLayout<UInt32>.size
        let byteArray = withUnsafePointer(to: &bigEndian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        return [UInt8](arrayLiteral: byteArray[0], byteArray[1], byteArray[2], byteArray[3])
    }

    public func toUInt8LittleEndianArray() -> [UInt8] {
        toUInt8Array().reversed()
    }

    public func toUInt16LittleEndianArray() -> [UInt8] {
        toUInt16Array().reversed()
    }

    public func toUInt24LittleEndianArray() -> [UInt8] {
        toUInt24Array().reversed()
    }

    public func toUInt32LittleEndianArray() -> [UInt8] {
        toUInt32Array().reversed()
    }
}

func toUInt32(array: [UInt8]) -> Int {
    Int(UInt32(bytes: array))
}

func toUInt24(array: [UInt8]) -> Int {
    Int(UInt32(bytes: array))
}

func toUInt16(array: [UInt8]) -> UInt16 {
    UInt16(bytes: array)
}