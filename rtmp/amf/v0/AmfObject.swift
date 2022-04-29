//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//
// A Map of others amf packets where key is an AmfString and value could be any amf packet
//

import Foundation

public class AmfObject: AmfData {

    private var properties = [AmfString : AmfData]()
    internal var bodySize = 0

    public init(properties: [AmfString : AmfData] = [AmfString : AmfData]()) {
        self.properties = properties
    }

    public func getProperty(name: String) -> AmfData? {
        for (key, value) in properties {
            if (key.value == name) {
                return value
            }
        }
        return nil
    }

    public func setProperty(name: String, data: String) {
        let key = AmfString(value: name)
        let value = AmfString(value: data)
        properties[key] = value
        bodySize += key.getSize()
        bodySize += value.getSize() + 1
    }

    public func setProperty(name: String, data: Bool) {
        let key = AmfString(value: name)
        let value = AmfBoolean(value: data)
        properties[key] = value
        bodySize += key.getSize()
        bodySize += value.getSize() + 1
    }

    public func setProperty(name: String) {
        let key = AmfString(value: name)
        let value = AmfNull()
        properties[key] = value
        bodySize += key.getSize()
        bodySize += value.getSize() + 1
    }

    public func setProperty(name: String, data: Double) {
        let key = AmfString(value: name)
        let value = AmfNumber(value: data)
        properties[key] = value
        bodySize += key.getSize()
        bodySize += value.getSize() + 1
    }

    public override func readBody(socket: Socket) throws {
        let objectEnd = AmfObjectEnd()
        while (!objectEnd.found) {
            try objectEnd.readBody(socket: socket)
            if (objectEnd.found) {
                bodySize += objectEnd.getSize()
            } else {
                //add buffer to start of the next read called
                if (objectEnd.readBodyData != nil) {
                    socket.appendRead(buffer: objectEnd.readBodyData!)
                }

                let key = AmfString()
                try key.readBody(socket: socket)
                bodySize += key.getSize()

                let value = try AmfData.getAmfData(socket: socket)
                bodySize += value.getSize() + 1

                properties[key] = value
            }
        }
    }

    public override func writeBody(socket: Socket) throws {
        for (key, value) in properties {
            try key.writeBody(socket: socket)

            try value.writeHeader(socket: socket)
            try value.writeBody(socket: socket)
        }
        let objectEnd = AmfObjectEnd()
        try objectEnd.writeBody(socket: socket)
    }

    public override func getType() -> AmfType {
        AmfType.OBJECT
    }

    public override func getSize() -> Int {
        bodySize
    }
}