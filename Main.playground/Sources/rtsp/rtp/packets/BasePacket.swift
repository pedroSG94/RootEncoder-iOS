import Foundation

public class BasePacket {
    public let maxPacketSize: Int = RtpConstants.MTU - 28
    public var channelIdentifier: UInt8?
    public var rtpPort: Int?
    public var rtcpPort: Int?
    
    private var clock: Int64?
    private var seq: Int64 = 0
    private var ssrc: Int64?
    
    public init(clock: Int64) {
        self.clock = clock
        self.ssrc = Int64(Int.random(in: Int.min..<Int.max))
    }
    
    public func setPorts(rtpPort: Int, rtcpPort: Int) {
        self.rtpPort = rtpPort
        self.rtcpPort = rtcpPort
    }
    
    public func reset() {
        self.seq = 0
        self.ssrc = Int64(Int.random(in: Int.min..<Int.max))
    }
    
    public func getBuffer(size: Int) -> Array<UInt8> {
        var buffer = Array<UInt8>(repeating: 0, count: size)
        buffer[0] = UInt8(strtoul("10000000", nil, 2))
        buffer[1] = UInt8(RtpConstants.payloadType)
        setLongSSRC(buffer: &buffer, ssrc: &ssrc!)
        requestBuffer(buffer: &buffer)
        return buffer
    }
    
    public func updateTimeStamp(buffer: inout Array<UInt8>, timeStamp: Int64) {
        var ts = timeStamp * self.clock! / 1000000000
        setLong(buffer: &buffer, n: &ts, begin: 4, end: 8)
    }
    
    public func setLong(buffer: inout Array<UInt8>, n: inout Int64, begin: Int, end: Int) {
        let i = end - 1
        for i in stride(from: i, to: begin, by: -1) {
            buffer[i] = UInt8(n % 256)
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
    
    private func setLongSSRC(buffer: inout Array<UInt8>, ssrc: inout Int64) {
        setLong(buffer: &buffer, n: &ssrc, begin: 8, end: 12)
    }
    
    private func requestBuffer(buffer: inout Array<UInt8>) {
        buffer[1] &= 0x7F
    }
}
