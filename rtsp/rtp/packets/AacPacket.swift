import Foundation


public class AacPacket: BasePacket {
    
    init(sampleRate: Int) {
        super.init(clock: UInt64(sampleRate), payloadType: RtpConstants.payloadType + RtpConstants.audioTrack)
        channelIdentifier = RtpConstants.audioTrack
    }
    
    public override func createAndSendPacket(data: Frame, callback: (RtpFrame) -> Void) {
        let buffer = data.buffer!
        let ts = data.timeStamp!
        let length = Int(data.length!)
        let dts = ts * 1000
        var rtpBuffer = getBuffer(size: length + RtpConstants.rtpHeaderLength + 4)
        rtpBuffer[RtpConstants.rtpHeaderLength + 4...rtpBuffer.count - 1] = buffer[0...buffer.count - 1]
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
        var frame = RtpFrame()
        frame.timeStamp = rtpTs
        frame.length = rtpBuffer.count
        frame.buffer = rtpBuffer
        frame.channelIdentifier = channelIdentifier

        callback(frame)
    }
}
