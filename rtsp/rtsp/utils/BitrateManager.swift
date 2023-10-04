//
//  BitrateManager.swift
//  rtsp
//
//  Created by Pedro  on 4/10/23.
//

import Foundation

class BitrateManager {

    private let connectCheckerRtsp: ConnectCheckerRtsp
    private var bitrate: Int64 = 0
    private var timeStamp = Date().millisecondsSince1970

    init(connectCheckerRtsp: ConnectCheckerRtsp) {
        self.connectCheckerRtsp = connectCheckerRtsp
    }

    func calculateBitrate(size: Int64) {
        bitrate += size
        let timeDiff = Date().millisecondsSince1970 - timeStamp
        if timeDiff >= 1000 {
            self.connectCheckerRtsp.onNewBitrateRtsp(bitrate: UInt64(self.bitrate / (timeDiff / 1000)))
            timeStamp = Date().millisecondsSince1970
            bitrate = 0
        }
    }
}
