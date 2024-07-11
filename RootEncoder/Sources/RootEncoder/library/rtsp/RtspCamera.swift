//
// Created by Pedro  on 21/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public class RtspCamera: CameraBase {

    private var client: RtspClient!

    public init(view: UIView, connectChecker: ConnectChecker) {
        client = RtspClient(connectChecker: connectChecker)
        super.init(view: view)
    }

    public init(view: MetalView, connectChecker: ConnectChecker) {
        client = RtspClient(connectChecker: connectChecker)
        super.init(view: view)
    }
    
    public func setAuth(user: String, password: String) {
        client.setAuth(user: user, password: password)
    }

    public func reTry(delay: Int, reason: String, backUrl: String? = nil) -> Bool {
        let result = client.shouldRetry(reason: reason)
        if (result) {
            videoEncoder.forceKeyFrame()
            client.reconnect(delay: delay, backupUrl: backUrl)
        }
        return result
    }
    
    public func setRetries(reTries: Int) {
        client.setRetries(reTries: reTries)
    }
    
    public override func prepareAudioRtp(sampleRate: Int, isStereo: Bool) {
        super.prepareAudioRtp(sampleRate: sampleRate, isStereo: isStereo)
        client.setAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
    }

    public override func stopStreamRtp() {
        client.disconnect()
    }

    public override func startStreamRtp(endpoint: String) {
        client.connect(url: endpoint)
    }
    
    public override func setVideoCodecImp(codec: VideoCodec) {
        client.setVideoCodec(codec: codec)
    }
    
    public override func setAudioCodecImp(codec: AudioCodec) {
        client.setAudioCodec(codec: codec)
    }
    
    public override func getAacDataRtp(frame: Frame) {
        client.sendAudio(buffer: frame.buffer!, ts: frame.timeStamp!)
    }

    public override func getH264DataRtp(frame: Frame) {
        client.sendVideo(buffer: frame.buffer!, ts: frame.timeStamp!)
    }

    public override func onSpsPpsVpsRtp(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        client.setVideoInfo(sps: sps, pps: pps, vps: vps)
    }
    
    public func setLogs(enabled: Bool) {
        client.setLogs(enabled: enabled)
    }
}
