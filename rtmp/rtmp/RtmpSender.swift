//
// Created by Pedro  on 17/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class RtmpSender {

    private let aacFlvPacket = AacFlvPacket()
    private let thread = DispatchQueue(label: "RtspSender")
    private var running = false
    private let queue = ConcurrentFlvQueue()
    private let callback: ConnectCheckerRtmp
    private let commandManager: CommandManager
    var socket: Socket? = nil

    public init(callback: ConnectCheckerRtmp, commandManager: CommandManager) {
        self.callback = callback
        self.commandManager = commandManager
    }
    
    public func setVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        
    }
    
    public func setAudioInfo(sampleRate: Int, isStereo: Bool) {
        aacFlvPacket.sendAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
    }
    
    public func sendVideo(frame: Frame) {
        
    }
    
    public func sendAudio(frame: Frame) {
        aacFlvPacket.createFlvAudioPacket(
            data: frame,
            callback: { (flvPacket) in
                queue.add(frame: flvPacket)
            }
        )
    }
    
    public func start() {
        running = true
        thread.async {
            while (self.running) {
                let flvPacket = self.queue.poll()
                if (flvPacket == nil) {
                    usleep(100)
                    continue
                } else {
                    do {
                        if (flvPacket?.type == FlvType.VIDEO) {
                            let size = try self.commandManager.sendVideoPacket(flvPacket: flvPacket!, socket: self.socket!)
                            print("wrote Video packet, size: \(size)")
                        } else {
                            let size = try self.commandManager.sendAudioPacket(flvPacket: flvPacket!, socket: self.socket!)
                            print("wrote Audio packet, size: \(size)")
                        }

                    } catch let error {
                        self.callback.onConnectionFailedRtmp(reason: error.localizedDescription)
                        return
                    }
                }
            }
        }
    }

    public func stop() {
        running = false
        aacFlvPacket.reset()
    }
}
