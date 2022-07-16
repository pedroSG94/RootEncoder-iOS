//
// Created by Pedro  on 16/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class Aggregate: RtmpMessage {

    override func readBody(socket: Socket) throws {
        //TODO Not yet implemented
    }

    override func storeBody() -> [UInt8] {
        //TODO Not yet implemented
    }

    override func getType() -> MessageType {
        MessageType.AGGREGATE
    }

    override func getSize() -> Int {
        //TODO Not yet implemented
    }
}