import Foundation

public struct RtpFrame {
    var buffer: Array<UInt8>?
    var length: Int?
    var timeStamp: UInt64?
    var channelIdentifier: Int?
}
