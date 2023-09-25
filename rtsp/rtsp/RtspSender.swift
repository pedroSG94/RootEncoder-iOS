import Foundation

public class RtspSender {
    
    private var audioPacketizer: AacPacket?
    private var videoPacketizer: BasePacket?
    private var tcpSocket: BaseRtpSocket?
    private var tcpReport: BaseSenderReport?
    private let thread = DispatchQueue(label: "RtspSender")
    private var running = false
    private let queue = ConcurrentQueue()
    private let callback: ConnectCheckerRtsp

    public init(callback: ConnectCheckerRtsp) {
        self.callback = callback
    }

    public func setSocketInfo(mProtocol: Protocol, socket: Socket, videoClientPorts: Array<Int>, audioClientPorts: Array<Int>, videoServerPorts: Array<Int>, audioServerPorts: Array<Int>) {
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
            tcpSocket = RtpSocketUdp(callback: callback, host: socket.host, videoPorts: videoSocketPorts, audioPorts: audioSocketPorts)
            tcpReport = SenderReportUdp(callback: callback, host: socket.host, videoPorts: videoReportPorts, audioPorts: audioReportPorts)
            break
        }
    }

    public func setVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        if (vps == nil) {
            videoPacketizer = H264Packet(sps: sps, pps: pps)
        } else {
            videoPacketizer = H265Packet(sps: sps, pps: pps)
        }

    }
    
    public func setAudioInfo(sampleRate: Int) {
        audioPacketizer = AacPacket(sampleRate: 44100)
    }
    
    public func sendVideo(frame: Frame) {
        if (running) {
            videoPacketizer?.createAndSendPacket(
                data: frame,
                callback: { (rtpFrame) in
                    queue.add(frame: rtpFrame)
                }
            )
        }
    }
    
    public func sendAudio(frame: Frame) {
        if (running) {
            audioPacketizer?.createAndSendPacket(
                data: frame,
                callback: { (rtpFrame) in
                    queue.add(frame: rtpFrame)
                }
            )
        }
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
                    do {
                        try self.tcpSocket?.sendFrame(rtpFrame: frame!)
                        try self.tcpReport?.update(rtpFrame: frame!)
                    } catch let error {
                        self.callback.onConnectionFailedRtsp(reason: error.localizedDescription)
                        return
                    }
                }
            }
        }
    }

    public func stop() {
        running = false
        tcpReport?.close()
    }
}
