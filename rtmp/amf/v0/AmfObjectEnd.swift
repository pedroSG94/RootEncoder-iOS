//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//
// Packet used to indicate end of AmfObject and AmfEcmaArray.
// This is a final sequence of 3 bytes.
//

import Foundation

public class AmfObjectEnd: AmfData {

    private var found = false
    private let endSequence: [UInt8] = Array()

    public init(found: Bool = false) {
        self.found = found
        endSequence = [UInt8](arrayLiteral: 0x00, 0x000, getType().rawValue)
    }

    public override func readBody(socket: Socket) throws {
        let bytes = socket.readUntil(length: getSize())
        found = bytes == endSequence
    }

    public override func writeBody(socket: Socket) throws {
        socket.write(buffer: endSequence)
    }

    public override func getType() -> AmfType {
        AmfType.OBJECT_END
    }

    public override func getSize() -> Int {
        endSequence.count
    }
}