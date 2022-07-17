//
// Created by Pedro  on 5/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class CommandSessionHistory {

    private var commandHistory = [Int : String]()
    private var headerHistory = [RtmpHeader]()

    func setReadHeader(header: RtmpHeader) {
        headerHistory.append(header)
    }

    func getLastReadHeader(chunkStreamId: Int) -> RtmpHeader? {
        let reverseList = headerHistory.reversed()
        var h: RtmpHeader? = nil
        reverseList.forEach { header in
            if (header.basicHeader.chunkStreamId == chunkStreamId) {
                h = header
                return
            }
        }
        return h
    }

    func getName(id: Int) -> String? {
        commandHistory[id]
    }

    func setPacket(id: Int, name: String) {
        commandHistory[id] = name
    }

    func reset() {
        commandHistory.removeAll()
        headerHistory.removeAll()
    }
}