//
//  SenderReportTcp.swift
//  app
//
//  Created by Pedro on 11/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import Foundation

public class SenderReportTcp {
    
    private var socket: Socket?
    
    private let interval = 3000 //3s
    private let PACKET_LENGTH: UInt64 = 28
    
    private var videoBuffer = Array<UInt8>(repeating: 0, count: 28)
    private var audioBuffer = Array<UInt8>(repeating: 0, count: 28)
    
    private var videoTime: UInt64 = 0
    private var audioTime: UInt64 = 0
    private var videoPacketCount: UInt64 = 0
    private var videoOctetCount: UInt64 = 0
    private var audioPacketCount: UInt64 = 0
    private var audioOctetCount: UInt64 = 0
    
    public init(socket: Socket) {
        self.socket = socket
        
        /*                                 Version(2)  Padding(0)                                         */
        /*                                     ^          ^            PT = 0                                */
        /*                                     |          |                ^                                */
        /*                                     | --------                 |                                */
        /*                                     | |---------------------                                */
        /*                                     | ||                                                    */
        /*                                     | ||                                                    */
        videoBuffer[0] = UInt8(strtoul("10000000", nil, 2))
        audioBuffer[0] = UInt8(strtoul("10000000", nil, 2))

        /* Packet Type PT */
        videoBuffer[1] = 200
        audioBuffer[1] = 200

        /* Byte 2,3          ->  Length                             */
        var nVideo: UInt64 = PACKET_LENGTH / 4 - 1
        setLong(buffer: &videoBuffer, n: &nVideo, begin: 2, end: 4)
        var nAudio: UInt64 = PACKET_LENGTH / 4 - 1
        setLong(buffer: &audioBuffer, n: &nAudio, begin: 2, end: 4)
        /* Byte 4,5,6,7      ->  SSRC                            */
        var ssrcVideo = UInt64(Int.random(in: 0..<Int.max))
        setLong(buffer: &videoBuffer, n: &ssrcVideo, begin: 4, end: 8)
        var ssrcAudio = UInt64(Int.random(in: 0..<Int.max))
        setLong(buffer: &audioBuffer, n: &ssrcAudio, begin: 4, end: 8)
        /* Byte 8,9,10,11    ->  NTP timestamp hb                 */
        /* Byte 12,13,14,15  ->  NTP timestamp lb                 */
        /* Byte 16,17,18,19  ->  RTP timestamp                     */
        /* Byte 20,21,22,23  ->  packet count                      */
        /* Byte 24,25,26,27  ->  octet count                     */
        videoBuffer.insert(UInt8(28), at: 0)
        videoBuffer.insert(0, at: 0)
        videoBuffer.insert(1, at: 0)
        videoBuffer.insert([UInt8]("$".utf8)[0], at: 0)
        
        audioBuffer.insert(UInt8(28), at: 0)
        audioBuffer.insert(0, at: 0)
        audioBuffer.insert(1, at: 0)
        audioBuffer.insert([UInt8]("$".utf8)[0], at: 0)
    }
    
    public func updateAudio(rtpFrame: RtpFrame) {
        audioPacketCount += 1
        audioOctetCount += UInt64(rtpFrame.length!)
        
        setLong(buffer: &audioBuffer, n: &audioPacketCount, begin: 20, end: 24)
        setLong(buffer: &audioBuffer, n: &audioOctetCount, begin: 24, end: 28);
        let millis = UInt64(Date().millisecondsSince1970)
        if (millis - audioTime >= interval) {
            audioTime = UInt64(Date().millisecondsSince1970)
            let nano = UInt64(Date().millisecondsSince1970) * 1000000
            var ts = rtpFrame.timeStamp!
            self.setData(buffer: &audioBuffer, ntpts: nano, rtpts: &ts)
            sendReport(buffer: audioBuffer)
        }
    }
    
    public func updateVideo(rtpFrame: RtpFrame) {
        videoPacketCount += 1
        videoOctetCount += UInt64(rtpFrame.length!)
        
        setLong(buffer: &videoBuffer, n: &videoPacketCount, begin: 20, end: 24)
        setLong(buffer: &videoBuffer, n: &videoOctetCount, begin: 24, end: 28);
        let millis = UInt64(Date().millisecondsSince1970)
        if (millis - videoTime >= interval) {
            videoTime = UInt64(Date().millisecondsSince1970)
            let nano = UInt64(Date().millisecondsSince1970) * 1000000
            var ts = rtpFrame.timeStamp!
            self.setData(buffer: &videoBuffer, ntpts: nano, rtpts: &ts)
            sendReport(buffer: videoBuffer)
        }
    }
    
    public func sendReport(buffer: Array<UInt8>) {
        socket?.write(buffer: buffer)
        print("send audio report")
    }
    
    private func setLong(buffer: inout Array<UInt8>, n: inout UInt64, begin: Int32, end: Int32) {
        let start = end - 1
        for i in stride(from: start, to: begin - 1, by: -1) {
            buffer[Int(i)] = intToBytes(from: n % 256)[0]
            n >>= 8
        }
    }
    
    private func setData(buffer: inout Array<UInt8>, ntpts: UInt64, rtpts: inout UInt64) {
        var hb = ntpts / 1000000000
        var lb = ((ntpts - hb * 1000000000) * 4294967296) / 1000000000
        setLong(buffer: &buffer, n: &hb, begin: 8, end: 12)
        setLong(buffer: &buffer, n: &lb, begin: 12, end: 16)
        setLong(buffer: &buffer, n: &rtpts, begin: 16, end: 20)
    }
}
