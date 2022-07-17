//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class AmfEcmaArray: AmfObject {

    private var properties =  [AmfString : AmfData]()
    var length: Int = 0

    public override init(properties: [AmfString : AmfData] = [AmfString : AmfData]()) {
        super.init(properties: properties)
        self.properties = properties
        bodySize += 4
    }

    public override func setProperty(name: String, data: String) {
        super.setProperty(name: name, data: data)
        length = properties.count

    }

    public override func setProperty(name: String, data: Bool) {
        super.setProperty(name: name, data: data)
        length = properties.count

    }

    public override func setProperty(name: String) {
        super.setProperty(name: name)
        length = properties.count

    }

    public override func setProperty(name: String, data: Double) {
        super.setProperty(name: name, data: data)
        length = properties.count
    }

    public override func readBody(buffer: inout [UInt8]) throws {
        //get number of items as UInt32
        let bytes = buffer.takeFirst(n: 4)
        length = Int(UInt32(bytes: bytes))
        //read items
        try super.readBody(buffer: &buffer)
        bodySize += 4 //add length size to body
    }

    public override func writeBody() -> [UInt8] {
        //write number of items in the list as UInt32
        var bytes = [UInt8]()
        bytes.append(contentsOf: byteArray(from: length))
        //write items
        bytes.append(contentsOf: super.writeBody())
        return bytes
    }

    public override func getType() -> AmfType {
        AmfType.ECMA_ARRAY
    }
}
