//
//  G711Packet.swift
//  rtsp
//
//  Created by Pedro  on 21/3/24.
//
// RFC 7655
// Valid for G711A and G711U
//

import Foundation

public class RtspG711Packet: RtspBasePacket {
    
    init(sampleRate: Int) {
        super.init(clock: UInt64(sampleRate), payloadType: RtpConstants.payloadTypeG711)
        channelIdentifier = RtpConstants.trackAudio
    }
    
    public override func createAndSendPacket(buffer: Array<UInt8>, ts: UInt64, callback: (RtpFrame) -> Void) {
        let length = buffer.count
        let maxPayload = maxPacketSize - RtpConstants.rtpHeaderLength
        
        var sum = 0
        while (sum < length) {
            let size = if (length - sum < maxPayload) {
                length - sum
            } else {
                maxPayload
            }
            var rtpBuffer = getBuffer(size: size + RtpConstants.rtpHeaderLength)
            rtpBuffer[RtpConstants.rtpHeaderLength...rtpBuffer.count - 1] = buffer[0...buffer.count - 1]
            let dts = ts * 1000
            markPacket(buffer: &rtpBuffer)
            let rtpTs = updateTimeStamp(buffer: &rtpBuffer, timeStamp: dts)
            updateSeq(buffer: &rtpBuffer)

            var frame = RtpFrame()
            frame.timeStamp = rtpTs
            frame.length = rtpBuffer.count
            frame.buffer = rtpBuffer
            frame.channelIdentifier = channelIdentifier

            sum += size
            callback(frame)
        }
    }
}

