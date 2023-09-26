//
//  SenderReportTcp.swift
//  app
//
//  Created by Pedro on 11/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import Foundation

public class SenderReportTcp: BaseSenderReport {

    private var header = Array<UInt8>(arrayLiteral: [UInt8]("$".utf8)[0], 0x00, 0x00, 0x1C)
    private let socket: Socket

    public init(socket: Socket) {
        self.socket = socket
        super.init()
    }

    public override func sendReport(buffer: Array<UInt8>, rtpFrame: RtpFrame, packets: UInt64, octet: UInt64) throws {
        var report = buffer
        header[1] = UInt8(2 * rtpFrame.channelIdentifier! + 1)
        report.insert(contentsOf: header, at: 0)
        try socket.write(buffer: report, size: Int(PACKET_LENGTH) + header.count)
        let type = (rtpFrame.channelIdentifier == RtpConstants.trackAudio) ? "Audio" : "Video"
        print("send \(type) report, packets: \(packets), octet: \(octet)")
    }
}
