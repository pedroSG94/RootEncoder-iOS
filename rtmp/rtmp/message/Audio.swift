//
// Created by Pedro  on 16/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class Audio: RtmpMessage {

    private let flvPacket: FlvPacket

    public init(flvPacket: FlvPacket = FlvPacket(), streamId: Int = 0) {
        super.init(basicHeader: BasicHeader(chunkType: ChunkType.TYPE_0, chunkStreamId: Int(ChunkStreamId.AUDIO.rawValue)))
        super.header.messageStreamId = streamId
        super.header.timeStamp = Int(flvPacket.timeStamp)
        super.header.messageLength = flvPacket.length
    }

    override func readBody(body: [UInt8]) throws {
    }

    override func storeBody() -> [UInt8] {
        flvPacket.buffer
    }

    override func getType() -> MessageType {
        MessageType.AUDIO
    }

    override func getSize() -> Int {
        flvPacket.length
    }
}