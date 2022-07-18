//
// Created by Pedro  on 4/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
/**
* cs id (6 bits)
* fmt (2 bits)
* cs id - 64 (8 or 16 bits)
*
* 0 1 2 3 4 5 6 7
        * +-+-+-+-+-+-+-+-+
        * |fmt| cs id |
        * +-+-+-+-+-+-+-+-+
        * Chunk basic header 1
        *
        *
        * Chunk stream IDs 64-319 can be encoded in the 2-byte form of the
        * header. ID is computed as (the second byte + 64).
*
* 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
        * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        * |fmt| 0 | cs id - 64 |
        * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        * Chunk basic header 2
        *
        *
        * Chunk stream IDs 64-65599 can be encoded in the 3-byte version of
        * this field. ID is computed as ((the third byte)*256 + (the second
        * byte) + 64).
*
* 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3
        * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        * |fmt| 1 | cs id - 64 |
        * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        *
        * Chunk basic header 3
*/
//

import Foundation

public class BasicHeader: CustomStringConvertible {

    let chunkType: ChunkType
    let chunkStreamId: Int

    public init(chunkType: ChunkType, chunkStreamId: Int) {
        self.chunkType = chunkType
        self.chunkStreamId = chunkStreamId
    }

    public static func parseBasicHeader(socket: Socket) throws -> BasicHeader {
        let byte: UInt8 = try socket.readUntil(length: 1)[0]
        let chunkTypeValue = 0xff & byte >> 6
        guard let chunkType = ChunkType.init(rawValue: chunkTypeValue) else {
            throw IOException.runtimeError("Unknown chunk type value: \(chunkTypeValue)")
        }
        var chunkStreamIdValue = Int(byte & 0x3F)
        if (chunkTypeValue > 63) {
            throw IOException.runtimeError("Unknown chunk stream id value: \(chunkStreamIdValue)")
        }
        if (chunkTypeValue == 0) { //Basic header 2 Bytes
            let b: UInt8 = try socket.readUntil(length: 1)[0]
            chunkStreamIdValue = Int(b) - 64
        } else if (chunkStreamIdValue == 1) { //Basic header 3 Bytes
            let a: UInt8 = try socket.readUntil(length: 1)[0]
            let b: UInt8 = try socket.readUntil(length: 1)[0]
            let value = b & 0xff << 8 & a
            chunkStreamIdValue = Int(value) - 64
        }
        return BasicHeader(chunkType: chunkType, chunkStreamId: chunkStreamIdValue)
    }

    public func getHeaderSize(timestamp: Int) -> Int {
        var size = 0
        switch chunkType {
            case .TYPE_0:
                size = 12
            case .TYPE_1:
                size = 8
            case .TYPE_2:
                size = 4
            case .TYPE_3:
                size = 0

        }
        if (timestamp >= 0xffffff) {
            size += 4
        }
        return size
    }

    public var description: String {
        "BasicHeader(chunkType: \(chunkType), chunkStreamId: \(chunkStreamId))"
    }
}
