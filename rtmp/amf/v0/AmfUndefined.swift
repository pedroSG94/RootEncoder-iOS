//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class AmfUndefined: AmfData {

    public override func readBody(buffer: inout [UInt8]) throws {
    }

    public override func writeBody() -> [UInt8] {
    }

    public override func getType() -> AmfType {
        AmfType.UNDEFINED
    }

    public override func getSize() -> Int {
        0
    }
}