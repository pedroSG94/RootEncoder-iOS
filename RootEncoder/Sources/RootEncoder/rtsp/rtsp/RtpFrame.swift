import Foundation

public struct RtpFrame {
    var buffer: Array<UInt8>?
    var length: Int?
    var timeStamp: UInt64?
    var channelIdentifier: Int?
    
    public func isVideoFrame() -> Bool {
        channelIdentifier == RtpConstants.trackVideo
    }
}
