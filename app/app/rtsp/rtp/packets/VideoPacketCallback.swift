import Foundation

public protocol VideoPacketCallback {
    func onVideoFrameCreated(rtpFrame: inout RtpFrame)
}
