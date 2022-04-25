//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//
// Contain an empty body
//

import Foundation

public class AmfNull: AmfData {

    public override func readBody(socket: Socket) throws {
    }

    public override func writeBody(socket: Socket) throws {
    }

    public override func getType() -> AmfType {
        AmfType.NULL
    }

    public override func getSize() -> Int {
        0
    }
}