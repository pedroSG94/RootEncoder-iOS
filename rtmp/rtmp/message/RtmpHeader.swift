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

    func readHeader(socket: Socket) throws {

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
                <#code#>
            case .TYPE_1:
                <#code#>
            case .TYPE_2:
                <#code#>
            case .TYPE_3:
                <#code#>
        }
    }

    func getPacketLength() -> Int {
        messageLength + basicHeader.getHeaderSize(timestamp: timeStamp)
    }
}