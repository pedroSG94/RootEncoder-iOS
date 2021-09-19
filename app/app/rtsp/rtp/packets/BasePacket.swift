import Foundation

public class BasePacket {
    public let maxPacketSize: Int = RtpConstants.MTU - 28
    public var channelIdentifier: Int?
    public var rtpPort: UInt32?
    public var rtcpPort: UInt32?
    
    private var clock: UInt64
    private var seq: UInt64 = 0
    var ssrc: UInt64 = 0
    private var payloadType = 0
    
    public init(clock: UInt64, payloadType: Int) {
        self.clock = clock
        self.payloadType = payloadType
    }

    public func setSSRC(ssrc: UInt64) {
        self.ssrc = ssrc
    }

    public func setPorts(rtpPort: UInt32, rtcpPort: UInt32) {
        self.rtpPort = rtpPort
        self.rtcpPort = rtcpPort
    }
    
    public func reset() {
        seq = 0
        ssrc = 0
    }
    
    public func getBuffer(size: Int) -> Array<UInt8> {
        var buffer = Array<UInt8>(repeating: 0, count: size)
        buffer[0] = UInt8(0x80)
        buffer[1] = UInt8(payloadType)
        setLongSSRC(buffer: &buffer, ssrc: ssrc)
        requestBuffer(buffer: &buffer)
        return buffer
    }
    
    public func updateTimeStamp(buffer: inout Array<UInt8>, timeStamp: UInt64) -> UInt64 {
        let ts: UInt64 = timeStamp * clock / 1000000000
        setLong(buffer: &buffer, n: ts, begin: 4, end: 8)
        return ts
    }
    
    public func setLong(buffer: inout Array<UInt8>, n: UInt64, begin: Int32, end: Int32) {
        let start = end - 1
        var value = n
        for i in stride(from: start, to: begin - 1, by: -1) {
            buffer[Int(i)] = intToBytes(from: value % 256)[0]
            value >>= 8
        }
    }
    
    public func updateSeq(buffer: inout Array<UInt8>) {
        seq += 1
        setLong(buffer: &buffer, n: seq, begin: 2, end: 4)
    }
    
    public func markPacket(buffer: inout Array<UInt8>) {
        buffer[1] |= 0x80
    }
    
    private func setLongSSRC(buffer: inout Array<UInt8>, ssrc: UInt64) {
        setLong(buffer: &buffer, n: ssrc, begin: 8, end: 12)
    }
    
    private func requestBuffer(buffer: inout Array<UInt8>) {
        buffer[1] &= 0x7F
    }
}
