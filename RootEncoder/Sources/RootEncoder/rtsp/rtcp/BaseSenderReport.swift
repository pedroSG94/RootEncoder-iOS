//
// Created by Pedro  on 24/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation

public class BaseSenderReport {

    private let interval = 3000 //3s
    let PACKET_LENGTH: UInt64 = 28

    private var videoBuffer = Array<UInt8>(repeating: 0, count: RtpConstants.MTU)
    private var audioBuffer = Array<UInt8>(repeating: 0, count: RtpConstants.MTU)

    private var videoTime: UInt64 = 0
    private var audioTime: UInt64 = 0
    private var videoPacketCount: UInt64 = 0
    private var videoOctetCount: UInt64 = 0
    private var audioPacketCount: UInt64 = 0
    private var audioOctetCount: UInt64 = 0

    public init() {
        /*                                 Version(2)  Padding(0)                                         */
        /*                                     ^          ^            PT = 0                                */
        /*                                     |          |                ^                                */
        /*                                     | --------                 |                                */
        /*                                     | |---------------------                                */
        /*                                     | ||                                                    */
        /*                                     | ||                                                    */
        videoBuffer[0] = 0x80
        audioBuffer[0] = 0x80

        /* Packet Type PT */
        videoBuffer[1] = 0xC8
        audioBuffer[1] = 0xC8

        /* Byte 2,3          ->  Length                             */
        let nVideo: UInt64 = PACKET_LENGTH / 4 - 1
        setLong(buffer: &videoBuffer, n: nVideo, begin: 2, end: 4)
        let nAudio: UInt64 = PACKET_LENGTH / 4 - 1
        setLong(buffer: &audioBuffer, n: nAudio, begin: 2, end: 4)
        /* Byte 4,5,6,7      ->  SSRC                            */
        /* Byte 8,9,10,11    ->  NTP timestamp hb                 */
        /* Byte 12,13,14,15  ->  NTP timestamp lb                 */
        /* Byte 16,17,18,19  ->  RTP timestamp                     */
        /* Byte 20,21,22,23  ->  packet count                      */
        /* Byte 24,25,26,27  ->  octet count                     */

        //36, 1, 0, 28, 128, 200, 0, 6
        //-128, -56, 0, 6, 66, 77, -13, -22
    }

    public func setSSRC(ssrcVideo: UInt64, ssrcAudio: UInt64) {
        setLong(buffer: &videoBuffer, n: ssrcVideo, begin: 4, end: 8)
        setLong(buffer: &audioBuffer, n: ssrcAudio, begin: 4, end: 8)
    }

    public func update(rtpFrame: RtpFrame) throws -> Bool {
        if (rtpFrame.channelIdentifier == RtpConstants.trackVideo) {
            return try updateVideo(rtpFrame: rtpFrame)
        } else {
            return try updateAudio(rtpFrame: rtpFrame)
        }
    }

    private func updateAudio(rtpFrame: RtpFrame) throws -> Bool {
        audioPacketCount += 1
        audioOctetCount += UInt64(rtpFrame.length!)

        setLong(buffer: &audioBuffer, n: audioPacketCount, begin: 20, end: 24)
        setLong(buffer: &audioBuffer, n: audioOctetCount, begin: 24, end: 28);
        let millis = UInt64(Date().millisecondsSince1970)
        if (millis - audioTime >= interval) {
            audioTime = UInt64(Date().millisecondsSince1970)
            let nano = UInt64(Date().millisecondsSince1970) * 1000000
            setData(buffer: &audioBuffer, ntpts: nano, rtpts: rtpFrame.timeStamp!)
            try sendReport(buffer: audioBuffer, rtpFrame: rtpFrame)
            return true
        }
        return false
    }

    private func updateVideo(rtpFrame: RtpFrame) throws -> Bool {
        videoPacketCount += 1
        videoOctetCount += UInt64(rtpFrame.length!)

        setLong(buffer: &videoBuffer, n: videoPacketCount, begin: 20, end: 24)
        setLong(buffer: &videoBuffer, n: videoOctetCount, begin: 24, end: 28);
        let millis = UInt64(Date().millisecondsSince1970)
        if (millis - videoTime >= interval) {
            videoTime = UInt64(Date().millisecondsSince1970)
            let nano = UInt64(Date().millisecondsSince1970) * 1000000
            setData(buffer: &videoBuffer, ntpts: nano, rtpts: rtpFrame.timeStamp!)
            try sendReport(buffer: videoBuffer, rtpFrame: rtpFrame)
            return true
        }
        return false
    }

    /**
     This method must be overridden
     */
    func sendReport(buffer: Array<UInt8>, rtpFrame: RtpFrame) throws {
        
    }

    func close() {

    }
    
    public func flush() {
        
    }

    private func setLong(buffer: inout Array<UInt8>, n: UInt64, begin: Int32, end: Int32) {
        let start = end - 1
        var value = n
        for i in stride(from: start, to: begin - 1, by: -1) {
            buffer[Int(i)] = intToBytes(from: value % 256)[0]
            value >>= 8
        }
    }

    private func setData(buffer: inout Array<UInt8>, ntpts: UInt64, rtpts: UInt64) {
        let hb = ntpts / 1000000000
        let lb = ((ntpts - hb * 1000000000) * 4294967296) / 1000000000
        setLong(buffer: &buffer, n: hb, begin: 8, end: 12)
        setLong(buffer: &buffer, n: lb, begin: 12, end: 16)
        setLong(buffer: &buffer, n: rtpts, begin: 16, end: 20)
    }
}
