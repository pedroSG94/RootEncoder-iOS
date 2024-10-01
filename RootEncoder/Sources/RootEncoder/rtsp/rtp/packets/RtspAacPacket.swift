import Foundation


public class RtspAacPacket: RtspBasePacket {
    
    init(sampleRate: Int) {
        super.init(clock: UInt64(sampleRate), payloadType: RtpConstants.payloadType + RtpConstants.trackAudio)
        channelIdentifier = RtpConstants.trackAudio
    }
    
    public override func createAndSendPacket(mediaFrame: MediaFrame, callback: ([RtpFrame]) -> Void) {
        var fixedBuffer = mediaFrame.data
        let naluLength = mediaFrame.info.size
        let dts = mediaFrame.info.timestamp * 1000
        let maxPayload = maxPacketSize - RtpConstants.rtpHeaderLength
        var sum = 0
        var frames = [RtpFrame]()
        while (sum < naluLength) {
            let length = if (naluLength - sum < maxPayload) {
                naluLength - sum
            } else {
                maxPayload
            }
            var rtpBuffer = getBuffer(size: length + RtpConstants.rtpHeaderLength + 4)
            fixedBuffer.get(destiny: &rtpBuffer, index: RtpConstants.rtpHeaderLength + 4, length: length)
            markPacket(buffer: &rtpBuffer)
            let rtpTs = updateTimeStamp(buffer: &rtpBuffer, timeStamp: dts)
            
            // AU-headers-length field: contains the size in bits of a AU-header
            // 13+3 = 16 bits -> 13bits for AU-size and 3bits for AU-Index / AU-Index-delta
            // 13 bits will be enough because ADTS uses 13 bits for frame length
            rtpBuffer[RtpConstants.rtpHeaderLength] = 0x00
            rtpBuffer[RtpConstants.rtpHeaderLength + 1] = 0x10
            // AU-size
            rtpBuffer[RtpConstants.rtpHeaderLength + 2] = intToBytes(from: length >> 5)[0]
            rtpBuffer[RtpConstants.rtpHeaderLength + 3] = intToBytes(from: length << 3)[0]
            // AU-Index
            rtpBuffer[RtpConstants.rtpHeaderLength + 3] &= 0xF8
            rtpBuffer[RtpConstants.rtpHeaderLength + 3] |= 0x00
            
            updateSeq(buffer: &rtpBuffer)
            let frame = RtpFrame(buffer: rtpBuffer, length: rtpBuffer.count, timeStamp: rtpTs, channelIdentifier: channelIdentifier!)

            sum += length
            frames.append(frame)
        }
        if !frames.isEmpty { callback(frames) }
    }
}
