//
// Created by Pedro  on 16/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class RtmpCommand: RtmpMessage {

    var name: String
    var commandId: Int
    var data = [AmfData]()
    private var bodySize = 0

    public init(name: String, commandId: Int, timeStamp: Int, streamId: Int, basicHeader: BasicHeader) {
        self.name = name
        self.commandId = commandId
        super.init(basicHeader: basicHeader)
        let amfString = AmfString(value: name)
        bodySize += amfString.getSize() + 1
        data.append(amfString)
        let amfNumber = AmfNumber(value: Double(commandId))
        bodySize += amfNumber.getSize() + 1
        data.append(amfNumber)
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
        data.removeAll()
        var bytesRead = 0
        while (bytesRead < header.messageLength) {
            let amfData = try AmfData.getAmfData(buffer: &body)
            bytesRead += amfData.getSize() + 1
            data.append(amfData)
        }
        if (data.count > 0) {
            if (data[0] is AmfString) {
                let amfString = data[0] as! AmfString
                name = amfString.value
            }
            if (data.count >= 2 && data[1] is AmfNumber) {
                let amfNumber = data[1] as! AmfNumber
                commandId = Int(amfNumber.value)
            }
        }
        bodySize = bytesRead
        header.messageLength = bodySize
    }

    override func storeBody() -> [UInt8] {
        var bytes = [UInt8]()
        for element in data {
            bytes.append(contentsOf: element.writeHeader())
            bytes.append(contentsOf: element.writeBody())
        }
        return bytes
    }

    override func getSize() -> Int {
        bodySize
    }

    public override var description: String {
        "Command(name: \(name), commandId: \(commandId), data: \(data), bodySize: \(bodySize))"
    }
}
