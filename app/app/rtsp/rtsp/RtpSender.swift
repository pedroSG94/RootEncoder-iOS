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
    
    public func sendVideo(frame: Frame) {
        videoPacketizer?.createAndSendPacket(data: frame)
    }
    
    public func sendAudio(frame: Frame) {
        audioPacketizer?.createAndSendPacket(data: frame)
    }
    
    public func onVideoFrameCreated(rtpFrame: RtpFrame) {
        tcpSocket?.sendTcpFrame(rtpFrame: rtpFrame)
        tcpReport?.updateVideo(rtpFrame: rtpFrame)
    }
    
    public func onAudioFrameCreated(rtpFrame: RtpFrame) {
        tcpSocket?.sendTcpFrame(rtpFrame: rtpFrame)
        tcpReport?.updateAudio(rtpFrame: rtpFrame)
    }
}
