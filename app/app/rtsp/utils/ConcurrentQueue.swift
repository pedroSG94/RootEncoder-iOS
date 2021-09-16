//
// Created by Pedro  on 16/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation

class ConcurrentQueue {

    private var list: [RtpFrame] = []
    private let internalQueue: DispatchQueue = DispatchQueue(label:"ConcurrentQueue") 

    public func add(frame: RtpFrame) {
        internalQueue.sync{ list.append(frame)  }
    }

    public func poll() -> RtpFrame? {
        internalQueue.sync{
            if (list.isEmpty) {
                return nil
            } else {
                return list.removeFirst()
            }
        }
    }
}