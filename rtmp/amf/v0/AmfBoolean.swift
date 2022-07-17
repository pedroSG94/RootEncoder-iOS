//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//
// Only 1 byte of size where 0 is false and another value is true
//

import Foundation

public class AmfBoolean: AmfData {

    private var value: Bool

    public init(value: Bool = false) {
        self.value = value
    }

    public override func readBody(buffer: inout [UInt8]) throws {
        let byte = buffer.takeFirst(n: 1)[0]
        value = byte != 0x00
    }

    public override func writeBody() -> [UInt8] {
        let byte: UInt8 = value ? 0x01 : 0x00
        return [UInt8](arrayLiteral: byte)
    }

    public override func getType() -> AmfType {
        AmfType.BOOLEAN
    }

    public override func getSize() -> Int {
        1
    }
}