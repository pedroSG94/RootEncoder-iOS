import Foundation

public class BasePacket {
    public let maxPacketSize: Int = RtpConstants.MTU - 28
    public var channelIdentifier: UInt8?
    public var rtpPort: UInt32?
    public var rtcpPort: UInt32?
    
    private var clock: UInt64?
    private var seq: UInt64 = 0
    private var ssrc: UInt64?
    
    public init(clock: UInt64) {
        self.clock = clock
        self.ssrc = UInt64(UInt64(Int.random(in: 0..<Int.max)))
    }
    
    public func setPorts(rtpPort: UInt32, rtcpPort: UInt32) {
        self.rtpPort = rtpPort
        self.rtcpPort = rtcpPort
    }
    
    public func reset() {
        self.seq = 0
        self.ssrc = UInt64(Int.random(in: Int.min..<Int.max))
    }
    
    public func getBuffer(size: Int) -> Array<UInt8> {
        var buffer = Array<UInt8>(repeating: 0, count: size)
        buffer[0] = UInt8(strtoul("10000000", nil, 2))
        buffer[1] = UInt8(RtpConstants.payloadType)
        setLongSSRC(buffer: &buffer, ssrc: &ssrc!)
        requestBuffer(buffer: &buffer)
        return buffer
    }
    
    public func updateTimeStamp(buffer: inout Array<UInt8>, timeStamp: UInt64) {
        var ts: UInt64 = timeStamp * self.clock! / 1000000000
        setLong(buffer: &buffer, n: &ts, begin: 4, end: 8)
    }
    
    public func setLong(buffer: inout Array<UInt8>, n: inout UInt64, begin: Int32, end: Int32) {
        let start = end - 1
        for i in stride(from: start, to: begin - 1, by: -1) {
            buffer[Int(i)] = intToBytes(from: n % 256)[0]
            n >>= 8
        }
    }
    
    public func updateSeq(buffer: inout Array<UInt8>) {
        self.seq += 1
        setLong(buffer: &buffer, n: &seq, begin: 2, end: 4)
    }
    
    public func markPacket(buffer: inout Array<UInt8>) {
        buffer[1] |= 0x80
    }
    
    private func setLongSSRC(buffer: inout Array<UInt8>, ssrc: inout UInt64) {
        setLong(buffer: &buffer, n: &ssrc, begin: 8, end: 12)
    }
    
    private func requestBuffer(buffer: inout Array<UInt8>) {
        buffer[1] &= 0x7F
    }
}
