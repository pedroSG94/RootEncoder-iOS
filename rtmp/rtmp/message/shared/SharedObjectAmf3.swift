//
// Created by Pedro  on 16/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class SharedObjectAmf3: SharedObject {

    override func getType() -> MessageType {
        MessageType.SHARED_OBJECT_AMF3
    }
}