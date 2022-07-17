//
// Created by Pedro  on 16/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class SetPeerBandwidth: RtmpMessage {


    private var acknowledgementWindowSize: Int
    private var type: SetPeerBandwidthType

    public init(acknowledgementWindowSize: Int = 0, type: SetPeerBandwidthType = SetPeerBandwidthType.DYNAMIC) {
        self.acknowledgementWindowSize = acknowledgementWindowSize
        self.type = type
        super.init(basicHeader: BasicHeader(chunkType: ChunkType.TYPE_0,
                chunkStreamId: Int(ChunkStreamId.PROTOCOL_CONTROL.rawValue)))
    }

    override func readBody(body: inout [UInt8]) throws {
        acknowledgementWindowSize = Int(toUInt32(array: body.takeFirst(n: 4)))
        if let type = SetPeerBandwidthType.init(rawValue: body.takeFirst(n: 1)[0]) {
            self.type = type
        }
    }

    override func storeBody() -> [UInt8] {
        var bytes = [UInt8]()
        bytes.append(contentsOf: acknowledgementWindowSize.toUInt32Array())
        bytes.append(type.rawValue)
        return bytes
    }

    override func getType() -> MessageType {
        MessageType.SET_PEER_BANDWIDTH
    }

    override func getSize() -> Int {
        9
    }
}

public enum SetPeerBandwidthType: UInt8 {
    case HARD = 0x00
    case SOFT = 0x01
    case DYNAMIC = 0x02
}
