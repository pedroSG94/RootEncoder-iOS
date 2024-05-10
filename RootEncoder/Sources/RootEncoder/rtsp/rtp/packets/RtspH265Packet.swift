//
// Created by Pedro  on 25/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation

public class RtspH265Packet: RtspBasePacket {

    public init() {
        super.init(clock: UInt64(RtpConstants.clockVideoFrequency), payloadType: RtpConstants.payloadType + RtpConstants.trackVideo)
        channelIdentifier = RtpConstants.trackVideo
    }

    public override func createAndSendPacket(buffer: Array<UInt8>, ts: UInt64, callback: (RtpFrame) -> Void) {
        var buffer = buffer
        let dts = ts * 1000
        var frame = RtpFrame()
        frame.channelIdentifier = channelIdentifier

        var header = Array<UInt8>(repeating: 0, count: 6)
        buffer = buffer.get(destiny: &header, index: 0, length: 6)
        //128, 224, 0, 3, 0, 169, 138, 199, 7, 91, 205, 21, 98, 1, 64
        
        let naluLength = Int(buffer.count)
        let type: UInt8 = header[4] >> (1 & 0x3F)

        // Small NAL unit => Single NAL unit
        if (naluLength <= maxPacketSize - RtpConstants.rtpHeaderLength - 2) {
            var rtpBuffer = getBuffer(size: naluLength + RtpConstants.rtpHeaderLength + 2)
            rtpBuffer[RtpConstants.rtpHeaderLength] = header[4]
            rtpBuffer[RtpConstants.rtpHeaderLength + 1] = header[5]

            buffer = buffer.get(destiny: &rtpBuffer, index: RtpConstants.rtpHeaderLength + 2, length: naluLength)

            let rtpTs = updateTimeStamp(buffer: &rtpBuffer, timeStamp: dts)
            markPacket(buffer: &rtpBuffer)
            updateSeq(buffer: &rtpBuffer)

            frame.timeStamp = rtpTs
            frame.length = rtpBuffer.count
            frame.buffer = rtpBuffer
            callback(frame)
        }
        // Large NAL unit => Split nal unit
        else {
            //Set PayloadHdr (16bit type=49)
            header[0] = 49 << 1
            header[1] = 1
            // Set FU header
            //   +---------------+
            //   |0|1|2|3|4|5|6|7|
            //   +-+-+-+-+-+-+-+-+
            //   |S|E|  FuType   |
            //   +---------------+
            header[2] = type // FU header type
            header[2] += 0x80 // Start bit

            var sum = 0
            while sum < naluLength {
                var length = 0
                if (naluLength - sum > maxPacketSize - RtpConstants.rtpHeaderLength - 3) {
                    length = maxPacketSize - RtpConstants.rtpHeaderLength - 3
                } else {
                    length = buffer.count
                }
                var rtpBuffer = getBuffer(size: length + RtpConstants.rtpHeaderLength + 3)
                rtpBuffer[RtpConstants.rtpHeaderLength] = header[0]
                rtpBuffer[RtpConstants.rtpHeaderLength + 1] = header[1]
                rtpBuffer[RtpConstants.rtpHeaderLength + 2] = header[2]
                
                let rtpTs = updateTimeStamp(buffer: &rtpBuffer, timeStamp: dts)

                buffer = buffer.get(destiny: &rtpBuffer, index: RtpConstants.rtpHeaderLength + 3, length: length)

                sum += length
                if sum >= naluLength {
                    rtpBuffer[RtpConstants.rtpHeaderLength + 2] += 0x40
                    markPacket(buffer: &rtpBuffer)
                }
                updateSeq(buffer: &rtpBuffer)

                frame.timeStamp = rtpTs
                frame.length = rtpBuffer.count
                frame.buffer = rtpBuffer
                callback(frame)
                // Switch start bit
                header[2] = header[2] & 0x7F
            }
        }
    }

    override public func reset() {
        super.reset()
    }
}
