//
// Created by Pedro  on 12/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class RtmpMessage {

    private let basicHeader: BasicHeader
    lazy var header: RtmpHeader = {
        let h = RtmpHeader(basicHeader: basicHeader)
        h.messageType = getType()
        h.messageLength = getSize()
        return h
    }()

    init(basicHeader: BasicHeader) {
        self.basicHeader = basicHeader
    }

    public static func getMessage(socket: Socket, chunkSize: Int,
        commandSessionHistory: CommandSessionHistory) throws -> RtmpMessage {
        let header = try RtmpHeader.readHeader(socket: socket, commandSessionHistory: commandSessionHistory)
        let rtmpMessage: RtmpMessage
        switch header.messageType! {
        case .SET_CHUNK_SIZE:
            rtmpMessage = SetChunkSize()
        case .ABORT:
            rtmpMessage = Abort()
        case .ACKNOWLEDGEMENT:
            rtmpMessage = Acknowledgement()
        case .USER_CONTROL:
            rtmpMessage = UserControl()
        case .WINDOW_ACKNOWLEDGEMENT_SIZE:
            rtmpMessage = WindowAcknowledgementSize()
        case .SET_PEER_BANDWIDTH:
            rtmpMessage = SetPeerBandwidth()
        case .AUDIO:
            rtmpMessage = Audio()
        case .VIDEO:
            rtmpMessage = Video()
        case .DATA_AMF3:
            rtmpMessage = DataAmf3()
        case .SHARED_OBJECT_AMF3:
            rtmpMessage = SharedObjectAmf3()
        case .COMMAND_AMF3:
            rtmpMessage = CommandAmf3()
        case .DATA_AMF0:
            rtmpMessage = DataAmf0()
        case .SHARED_OBJECT_AMF0:
            rtmpMessage = SharedObjectAmf0()
        case .COMMAND_AMF0:
            rtmpMessage = CommandAmf0()
        case .AGGREGATE:
            rtmpMessage = Aggregate()
        }
        rtmpMessage.updateHeader(rtmpHeader: header)
        let body: [UInt8]
        if (header.messageLength > chunkSize) {
            body = try getInputWithoutChunks(socket: socket, header: header, chunkSize: chunkSize, commandSessionHistory: commandSessionHistory)
        } else {
            body = try socket.readUntil(length: header.messageLength)
        }
        try rtmpMessage.readBody(body: &body)
        return rtmpMessage
    }

    public static func getMarkType(byte: UInt8) throws -> MessageType {
        guard let value = MessageType.init(rawValue: byte) else {
            throw IOException.runtimeError("Unknown rtmp message type: \(byte)")
        }
        return value
    }

    private static func getInputWithoutChunks(socket: Socket, header: RtmpHeader, chunkSize: Int,
        commandSessionHistory: CommandSessionHistory) throws -> [UInt8] {
        var packetStore = [UInt8]()
        var bytesRead = 0
        while (bytesRead < header.messageLength) {
            let chunk: [UInt8]
            if (header.messageLength - bytesRead < chunkSize) {
                //last chunk
                chunk = try socket.readUntil(length: header.messageLength - bytesRead)
            } else {
                chunk = try socket.readUntil(length: chunkSize)
                //skip chunk header to discard it, set packet ts to indicate if you need read extended ts
                let _ = try RtmpHeader.readHeader(socket: socket, commandSessionHistory: commandSessionHistory, timestamp: header.timeStamp)
            }
            bytesRead += chunk.count
            packetStore.append(contentsOf: chunk)
        }
        return packetStore
    }

    func updateHeader(rtmpHeader: RtmpHeader) {
        header.basicHeader = rtmpHeader.basicHeader
        header.messageType = rtmpHeader.messageType
        header.messageLength = rtmpHeader.messageLength
        header.messageStreamId = rtmpHeader.messageStreamId
        header.timeStamp = rtmpHeader.timeStamp
    }

    func writeHeader(socket: Socket) throws {
        try header.writeHeader(socket: socket)
    }

    func writeBody(socket: Socket) throws {
        let chunkSize = RtmpConfig.writeChunkSize
        var bytes = storeBody()
        var pos = 0
        var length = getSize()
        while (length > chunkSize) {
            let bytesToWrite = bytes.takeFirst(n: chunkSize)
            try socket.write(buffer: bytesToWrite)
            length -= chunkSize
            pos += chunkSize
            // Write header for remain chunk
            try header.writeHeader(basicHeader: BasicHeader(chunkType: ChunkType.TYPE_3, chunkStreamId: header.basicHeader.chunkStreamId), socket: socket)
        }
        try socket.write(buffer: bytes)
    }

    /**
     * Override functions
     */
    func readBody(body: inout [UInt8]) throws {

    }

    func storeBody() -> [UInt8] {

    }

    func getType() -> MessageType{

    }

    func getSize() -> Int {

    }
}