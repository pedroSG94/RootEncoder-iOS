//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//
// A Map of others amf packets where key is an AmfString and value could be any amf packet
//

import Foundation

public class AmfObject: AmfData {

    public override func readBody(socket: Socket) throws {

    }

    public override func writeBody(socket: Socket) throws {

    }

    public override func getType() -> AmfType {
        AmfType.OBJECT
    }

    public override func getSize() -> Int {
        1
    }
}