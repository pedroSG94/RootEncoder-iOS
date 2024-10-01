//
// Created by Pedro  on 17/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class RtmpSender: BaseSender {

    private var videoPacket: RtmpBasePacket = RtmpH264Packet()
    private var audioPacket: RtmpBasePacket = RtmpAacPacket()
    private let commandManager: RtmpCommandManager
    var socket: Socket? = nil

    public init(callback: ConnectChecker, commandManager: RtmpCommandManager) {
        self.commandManager = commandManager
        super.init(callback: callback, tag: "RtmpSender")
    }
    
    public override func setVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
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
    
    public override func setAudioInfo(sampleRate: Int, isStereo: Bool) {
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
    
    public override func onRun() {
        while (self.running) {
            let mediaFrame = self.queue.dequeue()
            getFlvPacket(mediaFrame: mediaFrame, callback: { flvPacket in
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
                    self.callback.onConnectionFailed(reason: error.localizedDescription)
                    return
                }
            })
        }
    }

    public override func stopImp(clear: Bool = true) {
        audioPacket.reset()
        videoPacket.reset(resetInfo: clear)
    }

    private func getFlvPacket(mediaFrame: MediaFrame?, callback: (FlvPacket) -> Void) {
        guard let mediaFrame = mediaFrame else { return }
        switch mediaFrame.type {
        case .VIDEO:
            videoPacket.createFlvPacket(
                mediaFrame: mediaFrame,
                callback: { packet in callback(packet) }
            )
        case .AUDIO:
            audioPacket.createFlvPacket(
                mediaFrame: mediaFrame,
                callback: { packet in callback(packet) }
            )
        }
    }
}
