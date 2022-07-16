//
// Created by Pedro  on 16/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class Abort: RtmpMessage {

    private var chunkStreamId: Int

    public init(chunkStreamId: Int = 0) {
        super.init(basicHeader: BasicHeader(chunkType: ChunkType.TYPE_0,
                chunkStreamId: Int(ChunkStreamId.PROTOCOL_CONTROL.rawValue)))
        self.chunkStreamId = chunkStreamId
    }

    override func readBody(socket: Socket) throws {
        chunkStreamId = Int(toUInt32(array: try socket.readUntil(length: 4)))
    }

    override func storeBody() -> [UInt8] {
        chunkStreamId.toUInt32Array()
    }

    override func getType() -> MessageType {
        MessageType.ABORT
    }

    override func getSize() -> Int {
        4
    }
}