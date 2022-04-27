//
// Created by Pedro  on 24/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation

class SenderReportUdp: BaseSenderReport {

    private var videoSocket: Socket
    private var audioSocket: Socket
    var videoPorts: Array<Int>
    var audioPorts: Array<Int>

    public init(callback: ConnectCheckerRtsp, host: String, videoPorts: Array<Int>, audioPorts: Array<Int>) {
        self.videoPorts = videoPorts
        self.audioPorts = audioPorts
        videoSocket = Socket(host: host, localPort: videoPorts[0], port: videoPorts[1])
        audioSocket = Socket(host: host, localPort: audioPorts[0], port: audioPorts[1])
        do {
            try videoSocket.connect()
            try audioSocket.connect()
        } catch let error {
            callback.onConnectionFailedRtsp(reason: error.localizedDescription)
        }
        super.init()
    }

    public override func close() {
        videoSocket.disconnect()
        audioSocket.disconnect()
    }

    public override func sendReport(buffer: Array<UInt8>, rtpFrame: RtpFrame, packets: UInt64, octet: UInt64) throws {
        let isAudio = rtpFrame.channelIdentifier == RtpConstants.audioTrack
        var port = 0
        if (isAudio) {
            try audioSocket.write(buffer: buffer, size: Int(PACKET_LENGTH))
            port = audioPorts[1]
        } else {
            try videoSocket.write(buffer: buffer, size: Int(PACKET_LENGTH))
            port = videoPorts[1]
        }
        let type = isAudio ? "Audio" : "Video"
        print("send \(type) report, packets: \(packets), octet: \(octet), port: \(port)")
    }
}