//
// Created by Pedro  on 16/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class Data: RtmpMessage {

    private let name: String
    private var data = [AmfData]()
    private var bodySize = 0

    public init(name: String, timeStamp: Int, streamId: Int, basicHeader: BasicHeader) {
        super.init(basicHeader: basicHeader)
        self.name = name
        let amfString = AmfString(value: name)
        bodySize += amfString.getSize() + 1
        for (_, element) in data.enumerated() {
            bodySize += element.getSize() + 1
        }
        header.messageLength = bodySize
        header.timeStamp = timeStamp
        header.messageStreamId = streamId
    }

    public func addData(amfData: AmfData) {
        data.append(amfData)
        bodySize += amfData.getSize() + 1
        header.messageLength = bodySize
    }

    override func readBody(body: inout [UInt8]) throws {
        bodySize = 0
        let amfString = AmfString()
        try amfString.readHeader(buffer: &body)
        try amfString.readBody(buffer: &body)
        bodySize += amfString.getSize() + 1
        while (bodySize < header.messageLength) {
            let amfData = try AmfData.getAmfData(buffer: &body)
            data.append(amfData)
            bodySize += amfData.getSize() + 1
        }
    }

    override func storeBody() -> [UInt8] {
        var bytes = [UInt8]()
        let amfString = AmfString(value: name)
        bytes.append(contentsOf: amfString.writeHeader())
        bytes.append(contentsOf: amfString.writeBody())
        for (_, element) in data.enumerated() {
            bytes.append(contentsOf: element.writeHeader())
            bytes.append(contentsOf: element.writeBody())
        }
        return bytes
    }

    override func getSize() -> Int {
        bodySize
    }
}