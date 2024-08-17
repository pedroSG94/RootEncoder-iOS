import Foundation

public class RtspSender {
    
    private var audioPacketizer: RtspBasePacket?
    private var videoPacketizer: RtspBasePacket?
    private var rtpSocket: BaseRtpSocket?
    private var senderReport: BaseSenderReport?
    private var thread: Task<(), Never>? = nil
    private var running = false
    private var cacheSize = 10 * 1024 * 1024 / RtpConstants.MTU
    private let queue: SynchronizedQueue<[RtpFrame]>
    private let callback: ConnectChecker
    private let commandsManager: RtspCommandManager

    var audioFramesSent = 0
    var videoFramesSent = 0
    var droppedAudioFrames = 0
    var droppedVideoFrames = 0
    private let bitrateManager: BitrateManager
    var isEnableLogs = true
    
    public init(callback: ConnectChecker, commandsManager: RtspCommandManager) {
        self.callback = callback
        self.commandsManager = commandsManager
        queue = SynchronizedQueue<[RtpFrame]>(label: "RtspSenderQueue", size: cacheSize)
        bitrateManager = BitrateManager(connectChecker: callback)
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

    public func setVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        videoPacketizer = switch commandsManager.videoCodec {
        case VideoCodec.H264:
            RtspH264Packet(sps: sps, pps: pps)
        case VideoCodec.H265:
            RtspH265Packet()
        }
    }
    
    public func setAudioInfo(sampleRate: Int) {
        audioPacketizer = switch commandsManager.audioCodec {
        case AudioCodec.AAC:
            RtspAacPacket(sampleRate: sampleRate)
        case AudioCodec.G711:
            RtspG711Packet(sampleRate: sampleRate)
        }
    }
    
    public func sendVideo(buffer: Array<UInt8>, ts: UInt64) {
        if (running) {
            videoPacketizer?.createAndSendPacket(
                buffer: buffer, ts: ts,
                callback: { rtpFrame in
                    if (!queue.enqueue(rtpFrame)) {
                        print("Video frame discarded")
                        droppedVideoFrames += 1
                    }
                }
            )
        }
    }
    
    public func sendAudio(buffer: Array<UInt8>, ts: UInt64) {
        if (running) {
            audioPacketizer?.createAndSendPacket(
                buffer: buffer, ts: ts,
                callback: { rtpFrame in
                    if (!queue.enqueue(rtpFrame)) {
                        print("Audio frame discarded")
                        droppedAudioFrames += 1
                    }
                }
            )
        }
    }

    public func start() {
        let ssrcVideo = UInt64(Int.random(in: 0..<Int.max))
        let ssrcAudio = UInt64(Int.random(in: 0..<Int.max))
        videoPacketizer?.setSSRC(ssrc: ssrcVideo)
        audioPacketizer?.setSSRC(ssrc: ssrcAudio)
        senderReport?.setSSRC(ssrcVideo: ssrcVideo, ssrcAudio: ssrcAudio)
        queue.clear()
        running = true
        thread = Task(priority: .high) {
            let isTcp = self.rtpSocket is RtpSocketTcp
            while (self.running) {
                let frames = self.queue.dequeue()
                if let frames = frames {
                    do {
                        for frame in frames {
                            try self.rtpSocket?.sendFrame(rtpFrame: frame, isEnableLogs: self.isEnableLogs)
                            if (frame.channelIdentifier == RtpConstants.trackVideo) {
                                self.videoFramesSent += 1
                            } else {
                                self.audioFramesSent += 1
                            }
                            let packetSize = isTcp ? 4 + (frame.length ?? 0) : (frame.length ?? 0)
                            self.bitrateManager.calculateBitrate(size: Int64(packetSize * 8))
                            let updated = try self.senderReport?.update(rtpFrame: frame, isEnableLogs: self.isEnableLogs)
                            if (updated ?? false) {
                                //bytes to bits (4 is tcp header length)
                                let reportSize = isTcp ? self.senderReport?.PACKET_LENGTH ?? (0 + 4) : self.senderReport?.PACKET_LENGTH ?? 0
                                self.bitrateManager.calculateBitrate(size: Int64(reportSize) * 8)
                            }
                        }
                        self.rtpSocket?.flush()
                    } catch let error {
                        self.callback.onConnectionFailed(reason: error.localizedDescription)
                        return
                    }
                }
            }
        }
    }

    public func stop() {
        running = false
        thread?.cancel()
        thread = nil
        senderReport?.close()
        queue.clear()
        videoFramesSent = 0
        audioFramesSent = 0
        droppedVideoFrames = 0
        droppedAudioFrames = 0
    }
    
    public func hasCongestion(percentUsed: Float) -> Bool {
        let size = queue.itemsCount()
        let remaining = queue.remaining()
        let capacity = size + remaining
        return Double(size) >= Double(capacity) * Double(percentUsed) / 100 //more than 20% queue used. You could have congestion
    }
    
    public func resizeCache(newSize: Int) {
        queue.resizeSize(size: newSize)
    }
    
    public func getCacheSize() -> Int {
        return cacheSize
    }
    
    public func clearCache() {
        queue.clear()
    }
    
    public func setLogs(enable: Bool) {
        isEnableLogs = enable
    }
}
