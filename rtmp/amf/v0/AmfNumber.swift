//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//
// A number in 8 bytes IEEE-754 double precision floating point value
//

import Foundation

public class AmfNumber: AmfData, CustomStringConvertible {

    var value: Double = 0.0

    public init(value: Double = 0.0) {
        self.value = value
    }

    public override func readBody(buffer: inout [UInt8]) throws {
        let bytes = buffer.takeFirst(n: getSize())
        value = bytes.withUnsafeBytes {
            $0.load(fromByteOffset: 0, as: Double.self)
        }
    }

    public override func writeBody() -> [UInt8] {
        let bytes = withUnsafePointer(to: &value) {
            $0.withMemoryRebound(to: UInt8.self, capacity: getSize()) {
                Array(UnsafeBufferPointer(start: $0, count: getSize()))
            }
        }
        return bytes.reversed()
    }

    public override func getType() -> AmfType {
        AmfType.NUMBER
    }

    public override func getSize() -> Int {
        8
    }

    public var description: String {
        "AmfNumber(value: \(value))"
    }
}