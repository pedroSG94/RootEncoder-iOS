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

    public override func createAndSendPacket(buffer: Array<UInt8>, ts: UInt64, callback: ([RtpFrame]) -> Void) {
        var fixedBuffer = buffer
        let dts = ts * 1000

        var header = Array<UInt8>(repeating: 0, count: 6)
        fixedBuffer.get(destiny: &header, index: 0, length: header.count)
        
        let naluLength = Int(fixedBuffer.count)
        let type: UInt8 = header[4] >> (1 & 0x3F)
        var frames = [RtpFrame]()
        // Small NAL unit => Single NAL unit
        if (naluLength <= maxPacketSize - RtpConstants.rtpHeaderLength - 2) {
            var rtpBuffer = getBuffer(size: naluLength + RtpConstants.rtpHeaderLength + 2)
            rtpBuffer[RtpConstants.rtpHeaderLength] = header[4]
            rtpBuffer[RtpConstants.rtpHeaderLength + 1] = header[5]

            fixedBuffer.get(destiny: &rtpBuffer, index: RtpConstants.rtpHeaderLength + 2, length: naluLength)

            let rtpTs = updateTimeStamp(buffer: &rtpBuffer, timeStamp: dts)
            markPacket(buffer: &rtpBuffer)
            updateSeq(buffer: &rtpBuffer)

            let frame = RtpFrame(buffer: rtpBuffer, length: rtpBuffer.count, timeStamp: rtpTs, channelIdentifier: channelIdentifier!)
            frames.append(frame)
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
                let length = if (naluLength - sum > maxPacketSize - RtpConstants.rtpHeaderLength - 3) {
                    maxPacketSize - RtpConstants.rtpHeaderLength - 3
                } else {
                    fixedBuffer.count
                }
                var rtpBuffer = getBuffer(size: length + RtpConstants.rtpHeaderLength + 3)
                rtpBuffer[RtpConstants.rtpHeaderLength] = header[0]
                rtpBuffer[RtpConstants.rtpHeaderLength + 1] = header[1]
                rtpBuffer[RtpConstants.rtpHeaderLength + 2] = header[2]
                
                let rtpTs = updateTimeStamp(buffer: &rtpBuffer, timeStamp: dts)

                fixedBuffer.get(destiny: &rtpBuffer, index: RtpConstants.rtpHeaderLength + 3, length: length)

                sum += length
                if sum >= naluLength {
                    rtpBuffer[RtpConstants.rtpHeaderLength + 2] += 0x40
                    markPacket(buffer: &rtpBuffer)
                }
                updateSeq(buffer: &rtpBuffer)

                let frame = RtpFrame(buffer: rtpBuffer, length: rtpBuffer.count, timeStamp: rtpTs, channelIdentifier: channelIdentifier!)
                frames.append(frame)
                // Switch start bit
                header[2] = header[2] & 0x7F
            }
        }
        callback(frames)
    }

    override public func reset() {
        super.reset()
    }
}
