//
//  BitrateManager.swift
//  rtmp
//
//  Created by Pedro  on 18/10/23.
//

import Foundation

class BitrateManager {

    private let connectCheckerRtmp: ConnectCheckerRtmp
    private var bitrate: Int64 = 0
    private var timeStamp = Date().millisecondsSince1970

    init(connectCheckerRtmp: ConnectCheckerRtmp) {
        self.connectCheckerRtmp = connectCheckerRtmp
    }

    func calculateBitrate(size: Int64) {
        bitrate += size
        let timeDiff = Date().millisecondsSince1970 - timeStamp
        if timeDiff >= 1000 {
            self.connectCheckerRtmp.onNewBitrateRtmp(bitrate: UInt64(self.bitrate / (timeDiff / 1000)))
            timeStamp = Date().millisecondsSince1970
            bitrate = 0
        }
    }
}
