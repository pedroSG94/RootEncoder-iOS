//
// Created by Pedro  on 17/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class Acknowledgement: RtmpMessage {

    private var sequenceNUmber: Int

    public init(sequenceNUmber: Int = 0) {
        super.init(basicHeader: BasicHeader(chunkType: ChunkType.TYPE_0, chunkStreamId: Int(ChunkStreamId.PROTOCOL_CONTROL.rawValue)))
        self.sequenceNUmber = sequenceNUmber
    }

    override func readBody(body: inout [UInt8]) throws {
        sequenceNUmber = Int(toUInt32(array: body.takeFirst(n: 4)))
    }

    override func storeBody() -> [UInt8] {
        sequenceNUmber.toUInt32Array()
    }

    override func getType() -> MessageType {
        MessageType.ACKNOWLEDGEMENT
    }

    override func getSize() -> Int {
        4
    }
}