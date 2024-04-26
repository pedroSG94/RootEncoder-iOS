//
// Created by Pedro  on 16/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public struct Event {
    let data: Int
    let bufferLength: Int

    public init(data: Int, bufferLength: Int = -1) {
        self.data = data
        self.bufferLength = bufferLength
    }
}