//
// Created by Pedro  on 16/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class WindowAcknowledgementSize: RtmpMessage {

    var acknowledgementWindowSize: Int

    public init(acknowledgementWindowSize: Int = 0, timeStamp: Int = 0) {
        super.init(basicHeader: BasicHeader(chunkType: ChunkType.TYPE_0,
                chunkStreamId: Int(ChunkStreamId.PROTOCOL_CONTROL.rawValue)))
        self.acknowledgementWindowSize = acknowledgementWindowSize
        super.header.timeStamp = timeStamp
    }

    override func readBody(body: [UInt8]) throws {
        acknowledgementWindowSize = Int(toUInt32(array: Array(body[0...3])))
    }

    override func storeBody() -> [UInt8] {
        acknowledgementWindowSize.toUInt32Array()
    }

    override func getType() -> MessageType {
        MessageType.WINDOW_ACKNOWLEDGEMENT_SIZE
    }

    override func getSize() -> Int {
        4
    }
}