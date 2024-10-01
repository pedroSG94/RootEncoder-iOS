import Foundation

public class RtspSender: BaseSender {
    
    private var audioPacketizer: RtspBasePacket?
    private var videoPacketizer: RtspBasePacket?
    private var rtpSocket: BaseRtpSocket?
    private var senderReport: BaseSenderReport?
    private let commandsManager: RtspCommandManager
    
    public init(callback: ConnectChecker, commandsManager: RtspCommandManager) {
        self.commandsManager = commandsManager
        super.init(callback: callback, tag: "RtspSender")
    }

    public func setSocketInfo(mProtocol: Protocol, socket: Socket, videoClientPorts: Array<Int>, audioClientPorts: Array<Int>, videoServerPorts: Array<Int>, audioServerPorts: Array<Int>) {
        switch (mProtocol) {
        case .TCP:
            rtpSocket = RtpSocketTcp(socket: socket)
            senderReport = SenderReportTcp(socket: socket)
            break
        case .UDP:
            let videoReportPorts = Array<Int>(arrayLiteral: videoClientPorts[1], videoServerPorts[1])
            let audioReportPorts = Array<Int>(arrayLiteral: audioClientPorts[1], audioServerPorts[1])
            let videoSocketPorts = Array<Int>(arrayLiteral: videoClientPorts[0], videoServerPorts[0])
            let audioSocketPorts = Array<Int>(arrayLiteral: audioClientPorts[0], audioServerPorts[0])
            rtpSocket = RtpSocketUdp(callback: callback, host: socket.host, videoPorts: videoSocketPorts, audioPorts: audioSocketPorts)
            senderReport = SenderReportUdp(callback: callback, host: socket.host, videoPorts: videoReportPorts, audioPorts: audioReportPorts)
            break
        }
    }

    public override func setVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        videoPacketizer = switch commandsManager.videoCodec {
        case VideoCodec.H264:
            RtspH264Packet(sps: sps, pps: pps)
        case VideoCodec.H265:
            RtspH265Packet()
        }
    }
    
    public override func setAudioInfo(sampleRate: Int, isStereo: Bool) {
        audioPacketizer = switch commandsManager.audioCodec {
        case AudioCodec.AAC:
            RtspAacPacket(sampleRate: sampleRate)
        case AudioCodec.G711:
            RtspG711Packet(sampleRate: sampleRate)
        }
    }

    public override func onRun() {
        let ssrcVideo = UInt64(Int.random(in: 0..<Int.max))
        let ssrcAudio = UInt64(Int.random(in: 0..<Int.max))
        videoPacketizer?.setSSRC(ssrc: ssrcVideo)
        audioPacketizer?.setSSRC(ssrc: ssrcAudio)
        senderReport?.setSSRC(ssrcVideo: ssrcVideo, ssrcAudio: ssrcAudio)
        let isTcp = self.rtpSocket is RtpSocketTcp
        while (self.running) {
            let mediaFrame = self.queue.dequeue()
            getRtpPackets(mediaFrame: mediaFrame, callback: { rtpFrames in
                do {
                    var size = 0
                    var isVideo = false
                    for frame in rtpFrames {
                        try self.rtpSocket?.sendFrame(rtpFrame: frame)
                        let packetSize = isTcp ? 4 + frame.length : frame.length
                        size += packetSize
                        isVideo = frame.isVideoFrame()
                        if (isVideo) {
                            self.videoFramesSent += 1
                        } else {
                            self.audioFramesSent += 1
                        }
                        self.bitrateManager.calculateBitrate(size: Int64(packetSize * 8))
                        if (try self.senderReport?.update(rtpFrame: frame) == true) {
                            //bytes to bits (4 is tcp header length)
                            let reportSize = isTcp ? RtpConstants.REPORT_PACKET_LENGTH + 4 : RtpConstants.REPORT_PACKET_LENGTH
                            self.bitrateManager.calculateBitrate(size: Int64(reportSize) * 8)
                            if isEnableLogs {
                                print("wrote report")
                            }
                        }
                    }
                    self.rtpSocket?.flush()
                    if isEnableLogs {
                        let type = if isVideo { "Video" } else { "Audio" }
                        print("wrote \(type) packet, size \(size)")
                    }
                } catch let error {
                    self.callback.onConnectionFailed(reason: error.localizedDescription)
                    return
                }
            })
        }
    }

    public override func stopImp(clear: Bool = true) {
        senderReport?.close()
        videoPacketizer?.reset()
        audioPacketizer?.reset()
    }
    
    private func getRtpPackets(mediaFrame: MediaFrame?, callback: ([RtpFrame]) -> Void) {
        guard let mediaFrame = mediaFrame else { return }
        switch mediaFrame.type {
        case .VIDEO:
            videoPacketizer?.createAndSendPacket(
                mediaFrame: mediaFrame,
                callback: { frames in callback(frames) }
            )
        case .AUDIO:
            audioPacketizer?.createAndSendPacket(
                mediaFrame: mediaFrame,
                callback: { frames in callback(frames) }
            )
        }
    }
}
