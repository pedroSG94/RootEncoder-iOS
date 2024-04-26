//
// Created by Pedro  on 5/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation
import common

public class RtmpHeader: CustomStringConvertible {

    var basicHeader: BasicHeader

    init (basicHeader: BasicHeader) {
        self.basicHeader = basicHeader
    }

    var timeStamp = 0
    var messageLength = 0
    var messageType: MessageType? = nil
    var messageStreamId = 0

    public static func readHeader(socket: Socket, commandSessionHistory: CommandSessionHistory, timestamp: Int = 0) async throws -> RtmpHeader {
        let basicHeader = try await BasicHeader.parseBasicHeader(socket: socket)
        var timeStamp = timestamp
        var messageLength = 0
        var messageType: MessageType? = nil
        var messageStreamId = 0
        let lastHeader = commandSessionHistory.getLastReadHeader(chunkStreamId: basicHeader.chunkStreamId)
        switch basicHeader.chunkType {
            case .TYPE_0:
                timeStamp = toUInt24(array: try await socket.readUntil(length: 3))
                messageLength = toUInt24(array: try await socket.readUntil(length: 3))
                let b = try await socket.readUntil(length: 1)[0]
                messageType = try RtmpMessage.getMarkType(byte: b)
                messageStreamId = toUInt32(array: try await socket.readUntil(length: 4)).littleEndian
                //extended timestamp
                if (timeStamp >= 0xffffff) {
                    timeStamp = toUInt32(array: try await socket.readUntil(length: 4))
                }
        case .TYPE_1:
            if (lastHeader != nil) {
                messageStreamId = lastHeader!.messageStreamId
            }
            timeStamp = toUInt24(array: try await socket.readUntil(length: 3))
            messageLength = toUInt24(array: try await socket.readUntil(length: 3))
            messageType = try RtmpMessage.getMarkType(byte: try await socket.readUntil(length: 1)[0])
            //extended timestamp
            if (timeStamp >= 0xffffff) {
                timeStamp = toUInt32(array: try await socket.readUntil(length: 4))
            }
            case .TYPE_2:
                if (lastHeader != nil) {
                    messageStreamId = lastHeader!.messageStreamId
                    messageType = lastHeader!.messageType
                    messageLength = lastHeader!.messageLength
                }
                timeStamp = toUInt24(array: try await socket.readUntil(length: 3))
                //extended timestamp
                if (timeStamp >= 0xffffff) {
                    timeStamp = toUInt32(array: try await socket.readUntil(length: 4))
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
                    timeStamp = toUInt32(array: try await socket.readUntil(length: 4))
                }
        }
        let rtmpHeader = RtmpHeader(basicHeader: basicHeader)
        rtmpHeader.timeStamp = timeStamp
        rtmpHeader.messageLength = messageLength
        rtmpHeader.messageType = messageType
        rtmpHeader.messageStreamId = messageStreamId
        return rtmpHeader
    }

    func writeHeader(socket: Socket) async throws {
        try await writeHeader(basicHeader: basicHeader, socket: socket)
    }

    func writeHeader(basicHeader: BasicHeader, socket: Socket) async throws {
        //Write basic header byte
        let byte = basicHeader.chunkType.rawValue << 6 | UInt8(bitPattern: Int8(basicHeader.chunkStreamId))
        try await socket.write(buffer: [UInt8](arrayLiteral: byte))
        switch basicHeader.chunkType {
            case .TYPE_0:
                try await socket.write(buffer: min(timeStamp, 0xffffff).toUInt24Array())
                try await socket.write(buffer: messageLength.toUInt24Array())
                if let type = messageType {
                    try await socket.write(buffer: [UInt8](arrayLiteral: type.rawValue))
                }
                try await socket.write(buffer: messageStreamId.toUInt32LittleEndianArray())
                //extended timestamp
                if (timeStamp > 0xffffff) {
                    try await socket.write(buffer: timeStamp.toUInt32Array())
                }
            case .TYPE_1:
                try await socket.write(buffer: min(timeStamp, 0xffffff).toUInt24Array())
                try await socket.write(buffer: messageLength.toUInt24Array())
                if let type = messageType {
                    try await socket.write(buffer: [UInt8](arrayLiteral: type.rawValue))
                }
                //extended timestamp
                if (timeStamp > 0xffffff) {
                    try await socket.write(buffer: timeStamp.toUInt32Array())
                }
            case .TYPE_2:
                try await socket.write(buffer: min(timeStamp, 0xffffff).toUInt24Array())
                //extended timestamp
                if (timeStamp > 0xffffff) {
                    try await socket.write(buffer: timeStamp.toUInt32Array())
                }
            case .TYPE_3:
                //extended timestamp
                if (timeStamp > 0xffffff) {
                    try await socket.write(buffer: timeStamp.toUInt32Array())
                }
        }
    }

    func getPacketLength() -> Int {
        messageLength + basicHeader.getHeaderSize(timestamp: timeStamp)
    }

    public var description: String {
        "RtmpHeader(basicHeader: \(basicHeader), timeStamp: \(timeStamp), messageLength: \(messageLength), messageType: \(String(describing: messageType)), messageStreamId: \(messageStreamId))"
    }
}
