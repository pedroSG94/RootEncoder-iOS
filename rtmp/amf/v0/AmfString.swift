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

    public override func readBody(buffer: inout [UInt8]) throws {
        let lengthBytes = buffer.takeFirst(n: 2)
        let length = Int(UInt16(bytes: lengthBytes))
        bodySize = length + 2
        let valueBytes = buffer.takeFirst(n: length)
        value = String(bytes: valueBytes, encoding: .ascii)!
    }

    public override func writeBody() -> [UInt8] {
        var bytes = [UInt8]()
        let i16 = UInt16(bodySize - 2)
        bytes.append(contentsOf: byteArray(from: i16))
        let valueBytes: [UInt8] = Array(value.utf8)
        bytes.append(contentsOf: valueBytes)
        return bytes
    }

    public override func getType() -> AmfType {
        AmfType.STRING
    }

    public override func getSize() -> Int {
        bodySize
    }
}