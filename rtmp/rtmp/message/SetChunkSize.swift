//
// Created by Pedro  on 16/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class SetChunkSize: RtmpMessage {

    var chunkSize: Int

    public init(chunkSize: Int = 0) {
        super.init(basicHeader: BasicHeader(chunkType: ChunkType.TYPE_0,
                chunkStreamId: Int(ChunkStreamId.PROTOCOL_CONTROL.rawValue)))
        self.chunkSize = chunkSize
    }

    override func readBody(body: [UInt8]) throws {
        chunkSize = Int(toUInt32(array: Array(body[0...3])))
    }

    override func storeBody() -> [UInt8] {
        chunkSize.toUInt32Array()
    }

    override func getType() -> MessageType {
        MessageType.SET_CHUNK_SIZE
    }

    override func getSize() -> Int {
        4
    }
}