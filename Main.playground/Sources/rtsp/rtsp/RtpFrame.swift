import Foundation

public struct RtpFrame {
    var buffer: Array<UInt8>?
    var length: Int?
    var timeStamp: Int64?
    var rtpPort: Int?
    var rtcpPort: Int?
    var channelIdentifier: UInt8?
}
