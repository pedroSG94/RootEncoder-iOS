//
// Created by Pedro  on 17/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public class RtmpCamera: CameraBase, StreamClientListenter {
    
    public func onRequestKeyframe() {
        videoEncoder.forceKeyFrame()
    }
    private let client: RtmpClient
    private var streamClient: RtmpStreamClient?

    public init(view: UIView, connectChecker: ConnectChecker) {
        client = RtmpClient(connectChecker: connectChecker)
        super.init(view: view)
        streamClient = RtmpStreamClient(client: client, listener: self)
    }

    public init(view: MetalView, connectChecker: ConnectChecker) {
        client = RtmpClient(connectChecker: connectChecker)
        super.init(view: view)
        streamClient = RtmpStreamClient(client: client, listener: self)
    }
    
    public func getStreamClient() -> RtmpStreamClient {
        return streamClient!
    }
    
    public override func setVideoCodecImp(codec: VideoCodec) {
        client.setVideoCodec(codec: codec)
    }
    
    public override func setAudioCodecImp(codec: AudioCodec) {
        client.setAudioCodec(codec: codec)
    }

    public override func stopStreamRtp() {
        client.disconnect()
    }
    
    public override func startStreamRtp(endpoint: String) {
        if videoEncoder.rotation == 90 || videoEncoder.rotation == 270 {
            client.setVideoResolution(width: videoEncoder.height, height: videoEncoder.width)
        } else {
            client.setVideoResolution(width: videoEncoder.width, height: videoEncoder.height)
        }
        client.setFps(fps: videoEncoder.fps)
        client.connect(url: endpoint)
    }
    
    public override func prepareAudioRtp(sampleRate: Int, isStereo: Bool) {
        super.prepareAudioRtp(sampleRate: sampleRate, isStereo: isStereo)
        client.setAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
    }
    
    public override func getAacDataRtp(frame: Frame) {
        client.sendAudio(buffer: frame.buffer, ts: frame.timeStamp)
    }

    public override func getH264DataRtp(frame: Frame) {
        client.sendVideo(buffer: frame.buffer, ts: frame.timeStamp)
    }

    public override func onSpsPpsVpsRtp(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        client.setVideoInfo(sps: sps, pps: pps, vps: vps)
    }
}
