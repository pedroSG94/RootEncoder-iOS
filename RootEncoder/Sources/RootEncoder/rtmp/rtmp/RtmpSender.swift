//
// Created by Pedro  on 17/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class RtmpSender {

    private var videoPacket: RtmpBasePacket = RtmpH264Packet()
    private var audioPacket: RtmpBasePacket = RtmpAacPacket()
    private var thread: Task<(), Never>? = nil
    private var running = false
    private var cacheSize = 200
    private let queue: SynchronizedQueue<FlvPacket>
    private let callback: ConnectChecker
    private let commandManager: RtmpCommandManager
    var socket: Socket? = nil
    var audioFramesSent = 0
    var videoFramesSent = 0
    var droppedAudioFrames = 0
    var droppedVideoFrames = 0
    private let bitrateManager: BitrateManager
    var isEnableLogs = true

    public init(callback: ConnectChecker, commandManager: RtmpCommandManager) {
        self.callback = callback
        self.commandManager = commandManager
        self.queue = SynchronizedQueue<FlvPacket>(label: "RtmpSenderQueue", size: cacheSize)
        bitrateManager = BitrateManager(connectChecker: callback)
    }
    
    public func setVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        switch commandManager.videoCodec {
        case .H264:
            let packet = RtmpH264Packet()
            packet.setVideoInfo(sps: sps, pps: pps)
            videoPacket = packet
        case .H265:
            let packet = RtmpH265Packet()
            packet.setVideoInfo(sps: sps, pps: pps, vps: vps!)
            videoPacket = packet
        }
    }
    
    public func setAudioInfo(sampleRate: Int, isStereo: Bool) {
        switch commandManager.audioCodec {
        case .AAC:
            let packet = RtmpAacPacket()
            packet.sendAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
            audioPacket = packet
        case .G711:
            let packet = RtmpG711Packet()
            audioPacket = packet
        }
    }
    
    public func sendVideo(buffer: Array<UInt8>, ts: UInt64) {
        if (running) {
            videoPacket.createFlvPacket(
                buffer: buffer, ts: ts,
                callback: { (flvPacket) in
                    if (!queue.enqueue(flvPacket)) {
                        print("Video frame discarded")
                        droppedVideoFrames += 1
                    }
                }
            )
        }
    }
    
    public func sendAudio(buffer: Array<UInt8>, ts: UInt64) {
        if (running) {
            audioPacket.createFlvPacket(
                buffer: buffer, ts: ts,
                callback: { (flvPacket) in
                    if (!queue.enqueue(flvPacket)) {
                        print("Audio frame discarded")
                        droppedAudioFrames += 1
                    }
                }
            )
        }
    }
    
    public func start() {
        queue.clear()
        running = true
        thread = Task {
            while (self.running) {
                let flvPacket = self.queue.dequeue()
                if let flvPacket = flvPacket {
                    do {
                        if (flvPacket.type == FlvType.VIDEO) {
                            let size = try await self.commandManager.sendVideoPacket(flvPacket: flvPacket, socket: self.socket!)
                            if (self.isEnableLogs) {
                                print("wrote Video packet, size: \(size)")
                            }
                            self.videoFramesSent += 1
                            self.bitrateManager.calculateBitrate(size: Int64(size * 8))
                        } else {
                            let size = try await self.commandManager.sendAudioPacket(flvPacket: flvPacket, socket: self.socket!)
                            if (self.isEnableLogs) {
                                print("wrote Audio packet, size: \(size)")
                            }
                            self.audioFramesSent += 1
                            self.bitrateManager.calculateBitrate(size: Int64(size * 8))
                        }
                    } catch let error {
                        self.callback.onConnectionFailed(reason: error.localizedDescription)
                        return
                    }
                }
            }
        }
    }

    public func stop(clear: Bool = true) {
        running = false
        thread?.cancel()
        thread = nil
        audioPacket.reset()
        videoPacket.reset(resetInfo: clear)
        queue.clear()
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
}
