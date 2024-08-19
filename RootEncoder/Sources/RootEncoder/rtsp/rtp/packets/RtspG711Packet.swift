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
    
    public override func createAndSendPacket(buffer: Array<UInt8>, ts: UInt64, callback: ([RtpFrame]) -> Void) {
        var fixedBuffer = buffer
        let naluLength = fixedBuffer.count
        let maxPayload = maxPacketSize - RtpConstants.rtpHeaderLength
        var sum = 0
        var frames = [RtpFrame]()
        while (sum < naluLength) {
            let length = if (naluLength - sum < maxPayload) {
                naluLength - sum
            } else {
                maxPayload
            }
            var rtpBuffer = getBuffer(size: length + RtpConstants.rtpHeaderLength)
            fixedBuffer.get(destiny: &rtpBuffer, index: RtpConstants.rtpHeaderLength, length: length)
            let dts = ts * 1000
            markPacket(buffer: &rtpBuffer)
            let rtpTs = updateTimeStamp(buffer: &rtpBuffer, timeStamp: dts)
            updateSeq(buffer: &rtpBuffer)

            let frame = RtpFrame(buffer: rtpBuffer, length: rtpBuffer.count, timeStamp: rtpTs, channelIdentifier: channelIdentifier!)
            sum += length
            frames.append(frame)
        }
        callback(frames)
    }
}

