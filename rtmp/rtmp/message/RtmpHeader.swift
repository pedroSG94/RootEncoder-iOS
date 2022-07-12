//
// Created by Pedro  on 5/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class RtmpHeader {

    var basicHeader: BasicHeader

    init (basicHeader: BasicHeader) {
        self.basicHeader = basicHeader
    }

    var timeStamp = 0
    var messageLength = 0
    var messageType: MessageType? = nil
    var messageStreamId = 0

    public static func readHeader(socket: Socket, commandSessionHistory: CommandSessionHistory, timestamp: Int = 0) throws -> RtmpHeader {
        let basicHeader = try BasicHeader.parseBasicHeader(socket: socket)
        var timeStamp = timestamp
        var messageLength = 0
        var messageType: MessageType? = nil
        var messageStreamId = 0
        let lastHeader = commandSessionHistory.getLastReadHeader(chunkStreamId: basicHeader.chunkStreamId)
        switch basicHeader.chunkType {
            case .TYPE_0:
                timeStamp = toInt(array: try socket.readUntil(length: 3))
                messageLength = toInt(array: try socket.readUntil(length: 3))
                messageType = try RtmpMessage.getMarkType(byte: try socket.readUntil(length: 1)[0])
                messageStreamId = toInt(array: try socket.readUntil(length: 4)).littleEndian
                //extended timestamp
                if (timeStamp >= 0xffffff) {
                    timeStamp = toInt(array: try socket.readUntil(length: 4))
                }
        case .TYPE_1:
            if (lastHeader != nil) {
                messageStreamId = lastHeader!.messageStreamId
            }
            timeStamp = toInt(array: try socket.readUntil(length: 3))
            messageLength = toInt(array: try socket.readUntil(length: 3))
            messageType = try RtmpMessage.getMarkType(byte: try socket.readUntil(length: 1)[0])
            //extended timestamp
            if (timeStamp >= 0xffffff) {
                timeStamp = toInt(array: try socket.readUntil(length: 4))
            }
            case .TYPE_2:
                if (lastHeader != nil) {
                    messageStreamId = lastHeader!.messageStreamId
                    messageType = lastHeader!.messageType
                    messageLength = lastHeader!.messageLength
                }
                timeStamp = toInt(array: try socket.readUntil(length: 3))
                //extended timestamp
                if (timeStamp >= 0xffffff) {
                    timeStamp = toInt(array: try socket.readUntil(length: 4))
                }
            case .TYPE_3:
                if (lastHeader != nil) {
                    timeStamp = lastHeader!.timeStamp
                    messageStreamId = lastHeader!.messageStreamId
                    messageType = lastHeader!.messageType
                    messageLength = lastHeader!.messageLength
                }
                //extended timestamp
                if (timeStamp >= 0xffffff) {
                    timeStamp = toInt(array: try socket.readUntil(length: 4))
                }
        }
        var rtmpHeader = RtmpHeader(basicHeader: basicHeader)
        rtmpHeader.timeStamp = timeStamp
        rtmpHeader.messageLength = messageLength
        rtmpHeader.messageType = messageType
        rtmpHeader.messageStreamId = messageStreamId
        return rtmpHeader
    }

    func writeHeader(socket: Socket) throws {
        try writeHeader(basicHeader: basicHeader, socket: socket)
    }

    func writeHeader(basicHeader: BasicHeader, socket: Socket) throws {
        //Write basic header byte
        let byte = (Int(basicHeader.chunkType.rawValue) << 6) | basicHeader.chunkStreamId
        let unsigned = UInt8(bitPattern: Int8(byte))
        try socket.write(buffer: [UInt8](arrayLiteral: unsigned))
        switch basicHeader.chunkType {
            case .TYPE_0:
                try socket.write(buffer: min(timeStamp, 0xffffff).toUInt24Array())
                try socket.write(buffer: messageLength.toUInt24Array())
                if let type = messageType {
                    try socket.write(buffer: [UInt8](arrayLiteral: type.rawValue))
                }
                try socket.write(buffer: messageStreamId.toUInt32LittleEndianArray())
                //extended timestamp
                if (timeStamp > 0xffffff) {
                    try socket.write(buffer: timeStamp.toUInt32Array())
                }
            case .TYPE_1:
                try socket.write(buffer: min(timeStamp, 0xffffff).toUInt24Array())
                try socket.write(buffer: messageLength.toUInt24Array())
                if let type = messageType {
                    try socket.write(buffer: [UInt8](arrayLiteral: type.rawValue))
                }
                //extended timestamp
                if (timeStamp > 0xffffff) {
                    try socket.write(buffer: timeStamp.toUInt32Array())
                }
            case .TYPE_2:
                try socket.write(buffer: min(timeStamp, 0xffffff).toUInt24Array())
                //extended timestamp
                if (timeStamp > 0xffffff) {
                    try socket.write(buffer: timeStamp.toUInt32Array())
                }
            case .TYPE_3:
                //extended timestamp
                if (timeStamp > 0xffffff) {
                    try socket.write(buffer: timeStamp.toUInt32Array())
                }
        }
    }

    func getPacketLength() -> Int {
        messageLength + basicHeader.getHeaderSize(timestamp: timeStamp)
    }
}