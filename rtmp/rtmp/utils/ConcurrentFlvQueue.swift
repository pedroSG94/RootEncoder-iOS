//
//  ConcurrentFlvQueue.swift
//  app
//
//  Created by Pedro  on 16/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import Foundation

class ConcurrentFlvQueue {

    private var list: [FlvPacket] = []
    private let internalQueue: DispatchQueue = DispatchQueue(label:"ConcurrentFlvQueue")

    public func add(frame: FlvPacket) {
        internalQueue.sync{ list.append(frame)  }
    }

    public func poll() -> FlvPacket? {
        internalQueue.sync{
            if (list.isEmpty) {
                return nil
            } else {
                return list.removeFirst()
            }
        }
    }
}
