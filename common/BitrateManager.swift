//
//  BitrateManager.swift
//  rtsp
//
//  Created by Pedro  on 4/10/23.
//

import Foundation

public class BitrateManager {

    private let connectChecker: ConnectChecker
    private var bitrate: Int64 = 0
    private var timeStamp = Date().millisecondsSince1970

    public init(connectChecker: ConnectChecker) {
        self.connectChecker = connectChecker
    }

    public func calculateBitrate(size: Int64) {
        bitrate += size
        let timeDiff = Date().millisecondsSince1970 - timeStamp
        if timeDiff >= 1000 {
            self.connectChecker.onNewBitrate(bitrate: UInt64(self.bitrate / (timeDiff / 1000)))
            timeStamp = Date().millisecondsSince1970
            bitrate = 0
        }
    }
}
