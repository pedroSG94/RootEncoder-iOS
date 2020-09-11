//
//  RtpSocketTcp.swift
//  app
//
//  Created by Pedro on 10/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import Foundation

public class RtpSocketTcp {
    
    private var socket: Socket?
    
    init(socket: Socket) {
        self.socket = socket
    }
    
    public func sendTcpFrame(rtpFrame: inout RtpFrame) {
        let h3 = UInt8(rtpFrame.length! & 0xFF)
        rtpFrame.buffer?.insert(h3, at: 0)
        let h2 = UInt8(rtpFrame.length! >> 8)
        rtpFrame.buffer?.insert(h2, at: 0)
        let h1 = rtpFrame.channelIdentifier!
        rtpFrame.buffer?.insert(h1, at: 0)
        let h = [UInt8]("$".utf8)[0]
        rtpFrame.buffer?.insert(h, at: 0)
        
        socket?.write(buffer: rtpFrame.buffer!)
        
        print("wrote packet: \(rtpFrame.channelIdentifier == 0x00 ? "Audio" : "Video"), size: \(rtpFrame.length!)")
    }
}
