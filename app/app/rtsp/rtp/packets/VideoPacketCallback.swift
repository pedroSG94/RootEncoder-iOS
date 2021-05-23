import Foundation

public protocol VideoPacketCallback {
    func onVideoFrameCreated(rtpFrame: RtpFrame)
}
