//
// Created by Pedro  on 17/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class RtmpSender {

    private let h264FlvPacket = H264FlvPacket()
    private let aacFlvPacket = AacFlvPacket()
    private let thread = DispatchQueue(label: "RtmpSender")
    private var running = false
    private var cacheSize = 200
    private let queue: SynchronizedQueue<FlvPacket>
    private let callback: ConnectCheckerRtmp
    private let commandManager: CommandManager
    var socket: Socket? = nil
    var audioFramesSent = 0
    var videoFramesSent = 0
    var droppedAudioFrames = 0
    var droppedVideoFrames = 0
    private let bitrateManager: BitrateManager
    var isEnableLogs = true

    public init(callback: ConnectCheckerRtmp, commandManager: CommandManager) {
        self.callback = callback
        self.commandManager = commandManager
        self.queue = SynchronizedQueue<FlvPacket>(label: "RtmpSenderQueue", size: cacheSize)
        bitrateManager = BitrateManager(connectCheckerRtmp: callback)
    }
    
    public func setVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        h264FlvPacket.setVideoInfo(sps: sps, pps: pps)
    }
    
    public func setAudioInfo(sampleRate: Int, isStereo: Bool) {
        aacFlvPacket.sendAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
    }
    
    public func sendVideo(buffer: Array<UInt8>, ts: UInt64) {
        if (running) {
            h264FlvPacket.createFlvVideoPacket(
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
            aacFlvPacket.createFlvAudioPacket(
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
        thread.async {
            while (self.running) {
                let flvPacket = self.queue.dequeue()
                if let flvPacket = flvPacket {
                    do {
                        if (flvPacket.type == FlvType.VIDEO) {
                            let size = try self.commandManager.sendVideoPacket(flvPacket: flvPacket, socket: self.socket!)
                            if (self.isEnableLogs) {
                                print("wrote Video packet, size: \(size)")
                            }
                            self.videoFramesSent += 1
                            self.bitrateManager.calculateBitrate(size: Int64(size * 8))
                        } else {
                            let size = try self.commandManager.sendAudioPacket(flvPacket: flvPacket, socket: self.socket!)
                            if (self.isEnableLogs) {
                                print("wrote Audio packet, size: \(size)")
                            }
                            self.audioFramesSent += 1
                            self.bitrateManager.calculateBitrate(size: Int64(size * 8))
                        }
                    } catch let error {
                        self.callback.onConnectionFailedRtmp(reason: error.localizedDescription)
                        return
                    }
                }
            }
        }
    }

    public func stop(clear: Bool = true) {
        running = false
        aacFlvPacket.reset()
        h264FlvPacket.reset(resetInfo: clear)
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
