//
// Created by Pedro  on 16/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class UserControl: RtmpMessage {

    private var bodySize: Int = 6
    var type: ControlType
    var event: Event

    public init(type: ControlType = ControlType.PING_REQUEST, event: Event = Event(data: -1, bufferLength: -1)) {
        super.init(basicHeader: BasicHeader(chunkType: ChunkType.TYPE_0,
                chunkStreamId: Int(ChunkStreamId.PROTOCOL_CONTROL.rawValue)))
        self.type = type
        self.event = event
    }

    override func readBody(body: [UInt8]) throws {
        bodySize = 0
        let t = toUInt16(array: Array(body.dropFirst(2)))
        if let type = ControlType.init(rawValue: UInt8(t)) {
            self.type = type
        }
        bodySize += 2
        let data = Int(toUInt32(array: Array(body.dropFirst(4))))
        bodySize += 4
        if (type == ControlType.SET_BUFFER_LENGTH) {
            let bufferLength = Int(toUInt32(array: Array(body.dropFirst(4))))
            event = Event(data: data, bufferLength: bufferLength)
        } else {
            event = Event(data: data)
        }
    }

    override func storeBody() -> [UInt8] {
        var bytes = [UInt8]()
        bytes.append(contentsOf: Int(type.rawValue).toUInt16Array())
        bytes.append(contentsOf: event.data.toUInt32Array())
        if (event.bufferLength != -1) {
            bytes.append(contentsOf: event.bufferLength.toUInt32Array())
        }
    }

    override func getType() -> MessageType {
        MessageType.USER_CONTROL
    }

    override func getSize() -> Int {
        bodySize
    }
}