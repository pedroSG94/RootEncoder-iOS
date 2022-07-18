//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//
// Packet used to indicate end of AmfObject and AmfEcmaArray.
// This is a final sequence of 3 bytes.
//

import Foundation

public class AmfObjectEnd: AmfData {

    var found = false
    private let endSequence: [UInt8]
    private let type = AmfType.OBJECT_END

    public init(found: Bool = false) {
        self.found = found
        endSequence = [UInt8](arrayLiteral: 0x00, 0x000, type.rawValue)
    }

    public override func readBody(buffer: inout [UInt8]) throws {
        let bytes = Array(buffer.prefix(upTo: getSize()))
        found = bytes == endSequence
        if (found) {
            buffer.removeFirst(getSize())
        }
    }

    public override func writeBody() -> [UInt8] {
        endSequence
    }

    public override func getType() -> AmfType {
        type
    }

    public override func getSize() -> Int {
        endSequence.count
    }

    public var description: String {
        "AmfObjectEnd(found: \(found), endSequence: \(endSequence), type: \(type))"
    }
}