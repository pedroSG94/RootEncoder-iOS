//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//
// A list of any amf packets that start with an UInt32 to indicate number of items
//

import Foundation

public class AmfStrictArray: AmfData {

    private var items: [AmfData] = Array()
    private var bodySize = 0

    public init(items: [AmfData] = Array()) {
        self.items = items
        bodySize += 4
        items.forEach { amfData in
            bodySize += amfData.getSize() + 1
        }
    }

    public override func readBody(socket: Socket) throws {
        items.removeAll()
        bodySize = 0
        //get number of items as UInt32
        let lengthBytes = socket.readUntil(length: 4)
        let length = lengthBytes.withUnsafeBytes {
            $0.load(fromByteOffset: 0, as: UInt32.self)
        }
        //read items
        for i in 0...length {
            let amfData: AmfData = try AmfData.getAmfData(socket: socket)
            bodySize += amfData.getSize() + 1
            items.append(amfData)
        }
    }

    public override func writeBody(socket: Socket) throws {
        //write number of items in the list as UInt32
        let bytes = withUnsafePointer(to: UInt32(items.count)) {
            $0.withMemoryRebound(to: UInt8.self, capacity: getSize()) {
                Array(UnsafeBufferPointer(start: $0, count: getSize()))
            }
        }
        socket.write(buffer: bytes)
        //write items
        items.forEach { amfData in
            amfData.writeHeader(socket: socket)
            amfData.writeBody(socket: socket)
        }
    }

    public override func getType() -> AmfType {
        AmfType.STRICT_ARRAY
    }

    public override func getSize() -> Int {
        bodySize
    }
}