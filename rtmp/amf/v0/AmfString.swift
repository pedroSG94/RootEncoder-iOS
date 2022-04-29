//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//
// A string encoded in ASCII where 2 first bytes indicate string size
//

import Foundation

public class AmfString: AmfData {

    var value: String = ""
    private var bodySize: Int = 2

    public init(value: String = "") {
        self.value = value
        bodySize = Array(value.utf8).count + 2
    }

    public override func readBody(socket: Socket) throws {
        let lengthBytes = try socket.readUntil(length: 2)
        let length = Int(UInt16(bytes: lengthBytes))
        bodySize = length + 2
        let valueBytes = try socket.readUntil(length: length)
        value = String(bytes: valueBytes, encoding: .ascii)!
    }

    public override func writeBody(socket: Socket) throws {
        let i16 = UInt16(bodySize - 2)
        try socket.write(buffer: byteArray(from: i16))
        let valueBytes: [UInt8] = Array(value.utf8)
        try socket.write(buffer: valueBytes)
    }

    public override func getType() -> AmfType {
        AmfType.STRING
    }

    public override func getSize() -> Int {
        bodySize
    }
}