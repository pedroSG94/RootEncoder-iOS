import Foundation

public class RtpSender: AudioPacketCallback, VideoPacketCallback {
    
    private var audioPacketizer: AacPacket?
    private var videoPacketizer: H264Packet?
    private let tcpSocket: RtpSocketTcp?
    private let tcpReport: SenderReportTcp?
    
    public init(socket: Socket) {
        tcpSocket = RtpSocketTcp(socket: socket)
        tcpReport = SenderReportTcp(socket: socket)
    }
    
    public func setVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>) {
        videoPacketizer = H264Packet(sps: sps, pps: pps, videoPacketCallback: self)
    }
    
    public func setAudioInfo(sampleRate: Int) {
        audioPacketizer = AacPacket(sampleRate: 44100, audioPacketCallback: self)
    }
    
    public func sendVideo(buffer: Array<UInt8>, ts: UInt64) {
        videoPacketizer?.createAndSendPacket(buffer: buffer, ts: ts)
    }
    
    public func sendAudio(buffer: Array<UInt8>, ts: UInt64) {
        audioPacketizer?.createAndSendPacket(buffer: buffer, ts: ts)
    }
    
    public func onVideoFrameCreated(rtpFrame: inout RtpFrame) {
        tcpSocket?.sendTcpFrame(rtpFrame: &rtpFrame)
        tcpReport?.updateVideo(rtpFrame: rtpFrame)
    }
    
    public func onAudioFrameCreated(rtpFrame: inout RtpFrame) {
        tcpSocket?.sendTcpFrame(rtpFrame: &rtpFrame)
        tcpReport?.updateAudio(rtpFrame: rtpFrame)
    }
}
