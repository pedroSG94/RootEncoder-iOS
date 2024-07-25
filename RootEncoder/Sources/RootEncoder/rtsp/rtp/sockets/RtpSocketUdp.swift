//
// Created by Pedro  on 24/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation

public class RtpSocketUdp: BaseRtpSocket, SocketCallback {

    private var videoSocket: Socket
    private var audioSocket: Socket
    private var videoPorts: Array<Int>
    private var audioPorts: Array<Int>
    private let connectChecker: ConnectChecker

    public init(callback: ConnectChecker, host: String, videoPorts: Array<Int>, audioPorts: Array<Int>) {
        self.videoPorts = videoPorts
        self.audioPorts = audioPorts
        self.connectChecker = callback
        videoSocket = Socket(host: host, localPort: videoPorts[0], port: videoPorts[1], callback: nil)
        audioSocket = Socket(host: host, localPort: audioPorts[0], port: audioPorts[1], callback: nil)
        do {
            try videoSocket.connect()
            try audioSocket.connect()
        } catch let error {
            callback.onConnectionFailed(reason: error.localizedDescription)
        }
        super.init()
        videoSocket.setCallback(callback: self)
        audioSocket.setCallback(callback: self)
    }

    public override func close() {
        videoSocket.disconnect()
        audioSocket.disconnect()
    }

    public override func sendFrame(rtpFrame: RtpFrame, isEnableLogs: Bool) throws {
        let isAudio = rtpFrame.channelIdentifier == RtpConstants.trackAudio
        var port = 0
        if (isAudio) {
            try audioSocket.write(buffer: rtpFrame.buffer!)
            port = audioPorts[1]
        } else {
            try videoSocket.write(buffer: rtpFrame.buffer!)
            port = videoPorts[1]
        }
        if (isEnableLogs) {
            print("wrote packet: \(isAudio ? "Audio" : "Video"), size: \(rtpFrame.buffer!.count), port: \(port)")
        }
        
    }
    
    public override func flush() {
        audioSocket.flush()
        videoSocket.flush()
    }
    
    public func onSocketError(error: String) {
        self.connectChecker.onConnectionFailed(reason: error)
    }
}
