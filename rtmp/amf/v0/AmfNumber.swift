//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//
// A number in 8 bytes IEEE-754 double precision floating point value
//

import Foundation

public class AmfNumber: AmfData {

    private var value: Double = 0.0

    public init(value: Double = 0.0) {
        self.value = value
    }

    public override func readBody(socket: Socket) throws {
        let bytes = try socket.readUntil(length: getSize())
        value = bytes.withUnsafeBytes {
            $0.load(fromByteOffset: 0, as: Double.self)
        }
    }

    public override func writeBody(socket: Socket) throws {
        let bytes = withUnsafePointer(to: &value) {
            $0.withMemoryRebound(to: UInt8.self, capacity: getSize()) {
                Array(UnsafeBufferPointer(start: $0, count: getSize()))
            }
        }
        try socket.write(buffer: bytes)
    }

    public override func getType() -> AmfType {
        AmfType.NUMBER
    }

    public override func getSize() -> Int {
        8
    }
}