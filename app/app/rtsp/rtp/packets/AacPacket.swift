import Foundation


public class AacPacket: BasePacket {
    
    private var callback: AudioPacketCallback?
    
    init(sampleRate: Int, audioPacketCallback: AudioPacketCallback) {
        super.init(clock: UInt64(sampleRate))
        self.channelIdentifier = 0x00
        self.callback = audioPacketCallback
    }
    
    public func createAndSendPacket(buffer: Array<UInt8>, ts: UInt64) {
        let length = buffer.count
        let dts = ts * 1000
        var rtpBuffer = self.getBuffer(size: length + RtpConstants.rtpHeaderLength + 4)
        rtpBuffer[RtpConstants.rtpHeaderLength + 4...rtpBuffer.count - 1] = buffer[0...buffer.count - 1]
        self.markPacket(buffer: &rtpBuffer)
        self.updateTimeStamp(buffer: &rtpBuffer, timeStamp: dts)
        
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
        
        self.updateSeq(buffer: &rtpBuffer)
        var frame = RtpFrame()
        frame.timeStamp = UInt64(ts)
        frame.length = UInt32(rtpBuffer.count)
        frame.buffer = rtpBuffer
        frame.channelIdentifier = self.channelIdentifier
        frame.rtpPort = self.rtpPort
        frame.rtcpPort = self.rtcpPort
        callback?.onAudioFrameCreated(rtpFrame: &frame)
    }
}
