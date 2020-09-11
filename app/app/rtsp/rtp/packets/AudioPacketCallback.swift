import Foundation

public protocol AudioPacketCallback {
    func onAudioFrameCreated(rtpFrame: inout RtpFrame)
}
