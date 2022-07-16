//
// Created by Pedro  on 16/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class SetPeerBandwidth: RtmpMessage {


    private var acknowledgementWindowSize: Int
    private var type: SetPeerBandwidthType

    public init(acknowledgementWindowSize: Int = 0, type: SetPeerBandwidthType = SetPeerBandwidthType.DYNAMIC) {
        super.init(basicHeader: BasicHeader(chunkType: ChunkType.TYPE_0,
                chunkStreamId: Int(ChunkStreamId.PROTOCOL_CONTROL.rawValue)))
        self.acknowledgementWindowSize = acknowledgementWindowSize
        self.type = type
    }

    override func readBody(socket: Socket) throws {
        acknowledgementWindowSize = Int(toUInt32(array: try socket.readUntil(length: 4)))
        if let type = SetPeerBandwidthType.init(rawValue: try socket.readUntil(length: 1)[0]) {
            self.type = type
        }
    }

    override func storeBody() -> [UInt8] {
        var bytes = [UInt8]()
        bytes.append(contentsOf: acknowledgementWindowSize.toUInt32Array())
        bytes.append(type.rawValue)
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