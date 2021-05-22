//
//  RtpSocketTcp.swift
//  app
//
//  Created by Pedro on 10/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import Foundation

public class RtpSocketTcp {
    
    private var header = Array<UInt8>(arrayLiteral: [UInt8]("$".utf8)[0], 0x00, 0x00, 0x00)
    private var socket: Socket?
    
    init(socket: Socket) {
        self.socket = socket
    }
    
    public func sendTcpFrame(rtpFrame: inout RtpFrame) {
        header[1] = rtpFrame.channelIdentifier!
        header[2] = UInt8(rtpFrame.length! >> 8)
        header[3] = UInt8(rtpFrame.length! & 0xFF)
        rtpFrame.buffer?.insert(contentsOf: header, at: 0)
        
        socket?.write(buffer: rtpFrame.buffer!)
        print("wrote packet: \(rtpFrame.channelIdentifier == 0x00 ? "Audio" : "Video"), size: \(rtpFrame.buffer!.count)")
    }
}
