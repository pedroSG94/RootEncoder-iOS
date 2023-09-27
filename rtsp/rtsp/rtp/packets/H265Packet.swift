//
// Created by Pedro  on 25/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation

public class H265Packet: BasePacket {

    private var sendKeyFrame = false
    private var agregationPacket: Array<UInt8>?

    public init(sps: Array<UInt8>, pps: Array<UInt8>) {
        super.init(clock: UInt64(RtpConstants.clockVideoFrequency), payloadType: RtpConstants.payloadType + RtpConstants.trackVideo)
        channelIdentifier = RtpConstants.trackVideo
        setSpsPps(sps: sps, pps: pps)
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

        if type == RtpConstants.IDR_N_LP || type == RtpConstants.IDR_W_DLP || type == RtpConstants.CRA_NUT {
            var rtpBuffer = getBuffer(size: agregationPacket!.count + RtpConstants.rtpHeaderLength)
            let rtpTs = updateTimeStamp(buffer: &rtpBuffer, timeStamp: dts)
            markPacket(buffer: &rtpBuffer)
            rtpBuffer[RtpConstants.rtpHeaderLength...RtpConstants.rtpHeaderLength + agregationPacket!.count - 1] = agregationPacket![0...agregationPacket!.count - 1]
            updateSeq(buffer: &rtpBuffer)

            frame.timeStamp = rtpTs
            frame.length = rtpBuffer.count
            frame.buffer = rtpBuffer
            callback(frame)
            sendKeyFrame = true
        }
        if sendKeyFrame {
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
        } else {
            print("waiting for keyframe")
        }
    }

    private func setSpsPps(sps: Array<UInt8>, pps: Array<UInt8>) {
        let spsBuffer = sps
        let ppsBuffer = pps
        agregationPacket = Array<UInt8>()
        // AP NAL header is 48
        agregationPacket?.append(48 << 1)
        agregationPacket?.append(1)
        // Write NALU 1 size into the array (NALU 1 is the SPS).
        agregationPacket?.append(UInt8(spsBuffer.count) >> 0x08)
        agregationPacket?.append(UInt8(spsBuffer.count) & 0xFF)
        // Write NALU 1 into the array
        agregationPacket?.append(contentsOf: spsBuffer[0...spsBuffer.count - 1])
        // Write NALU 2 size into the array (NALU 2 is the PPS).
        agregationPacket?.append(UInt8(ppsBuffer.count) >> 0x08)
        agregationPacket?.append(UInt8(ppsBuffer.count) & 0xFF)
        // Write NALU 2 into the array
        agregationPacket?.append(contentsOf: ppsBuffer[0...ppsBuffer.count - 1])
    }

    override public func reset() {
        super.reset()
        sendKeyFrame = false
    }
}
