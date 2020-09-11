import Foundation

public class RtpSender: AudioPacketCallback {
    
    private var audioPacketizer: AacPacket?
    private let tcpSocket: RtpSocketTcp?
    private let tcpReport: SenderReportTcp?
    
    public init(socket: Socket) {
        tcpSocket = RtpSocketTcp(socket: socket)
        tcpReport = SenderReportTcp(socket: socket)
    }
    
    public func setAudioInfo(sampleRate: Int) {
        audioPacketizer = AacPacket(sampleRate: 44100, audioPacketCallback: self)
    }
    
    public func sendVideo(buffer: Array<UInt8>, ts: Int64) {
        
    }
    
    public func sendAudio(buffer: Array<UInt8>, ts: UInt64) {
        audioPacketizer?.createAndSendPacket(buffer: buffer, ts: ts)
    }
    
    public func onAudioFrameCreated(rtpFrame: inout RtpFrame) {
        tcpSocket?.sendTcpFrame(rtpFrame: &rtpFrame)
        tcpReport?.updateAudio(rtpFrame: rtpFrame)
    }
}
