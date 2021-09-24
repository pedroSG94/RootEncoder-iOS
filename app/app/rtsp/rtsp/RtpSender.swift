import Foundation

public class RtpSender: AudioPacketCallback, VideoPacketCallback {
    
    private var audioPacketizer: AacPacket?
    private var videoPacketizer: H264Packet?
    private var tcpSocket: BaseRtpSocket?
    private var tcpReport: BaseSenderReport?
    private let thread = DispatchQueue(label: "RtpSender")
    private var running = false
    private let queue = ConcurrentQueue()

    public func setSocketInfo(mProtocol: Protocol, socket: Socket, videoClientPorts: Array<Int>, audioClientPorts: Array<Int>,
                              videoServerPorts: Array<Int>, audioServerPorts: Array<Int>) {
        switch (mProtocol) {
        case .TCP:
            tcpSocket = RtpSocketTcp(socket: socket)
            tcpReport = SenderReportTcp(socket: socket)
            break
        case .UDP:
            let videoReportPorts = Array<Int>(arrayLiteral: videoClientPorts[1], videoServerPorts[1])
            let audioReportPorts = Array<Int>(arrayLiteral: audioClientPorts[1], audioServerPorts[1])
            let videoSocketPorts = Array<Int>(arrayLiteral: videoClientPorts[0], videoServerPorts[0])
            let audioSocketPorts = Array<Int>(arrayLiteral: audioClientPorts[0], audioServerPorts[0])
            tcpSocket = RtpSocketUdp(callback: socket.callback, host: socket.host!, videoPorts: videoSocketPorts, audioPorts: audioSocketPorts)
            tcpReport = SenderReportUdp(callback: socket.callback, host: socket.host!, videoPorts: videoReportPorts, audioPorts: audioReportPorts)
            break
        }
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
        queue.add(frame: rtpFrame)
    }
    
    public func onAudioFrameCreated(rtpFrame: RtpFrame) {
        queue.add(frame: rtpFrame)
    }

    public func start() {
        let ssrcVideo = UInt64(Int.random(in: 0..<Int.max))
        let ssrcAudio = UInt64(Int.random(in: 0..<Int.max))
        videoPacketizer?.setSSRC(ssrc: ssrcVideo)
        audioPacketizer?.setSSRC(ssrc: ssrcAudio)
        tcpReport?.setSSRC(ssrcVideo: ssrcVideo, ssrcAudio: ssrcAudio)
        running = true
        thread.async {
            while (self.running) {
                let frame = self.queue.poll()
                if (frame == nil) {
                    usleep(100)
                    continue
                } else {
                    self.tcpSocket?.sendFrame(rtpFrame: frame!)
                    self.tcpReport?.update(rtpFrame: frame!)
                }
            }
        }
    }

    public func stop() {
        running = false
        tcpReport?.close()
    }
}
