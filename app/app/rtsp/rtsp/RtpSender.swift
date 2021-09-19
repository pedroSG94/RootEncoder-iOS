import Foundation

public class RtpSender: AudioPacketCallback, VideoPacketCallback {
    
    private var audioPacketizer: AacPacket?
    private var videoPacketizer: H264Packet?
    private let tcpSocket: RtpSocketTcp?
    private let tcpReport: SenderReportTcp?
    private let thread = DispatchQueue(label: "RtpSender")
    private var running = false
    private let queue = ConcurrentQueue()

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
                    self.tcpSocket?.sendTcpFrame(rtpFrame: frame!)
                    if (frame!.channelIdentifier == RtpConstants.audioTrack) {
                        self.tcpReport?.updateAudio(rtpFrame: frame!)
                    } else {
                        self.tcpReport?.updateVideo(rtpFrame: frame!)
                    }
                }
            }
        }
    }

    public func stop() {
        running = false
    }
}
