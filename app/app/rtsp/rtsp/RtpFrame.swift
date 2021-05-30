import Foundation

public struct RtpFrame {
    var buffer: Array<UInt8>?
    var length: UInt32?
    var timeStamp: UInt64?
    var rtpPort: UInt32?
    var rtcpPort: UInt32?
    var channelIdentifier: Int?
}
