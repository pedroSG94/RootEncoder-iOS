//
// Created by Pedro  on 17/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public class RtmpCamera: CameraBase {
    
    private let client: RtmpClient
    private var streamClient: RtmpStreamClient?

    public init(view: UIView, connectChecker: ConnectChecker) {
        client = RtmpClient(connectChecker: connectChecker)
        super.init(view: view)
        streamClient = RtmpStreamClient(client: client, listener: videoEncoder.createStreamClientListener())
        
    }

    public init(view: MetalView, connectChecker: ConnectChecker) {
        client = RtmpClient(connectChecker: connectChecker)
        super.init(view: view)
        streamClient = RtmpStreamClient(client: client, listener: videoEncoder.createStreamClientListener())
    }
    
    public func getStreamClient() -> RtmpStreamClient {
        return streamClient!
    }
    
    override func setVideoCodecImp(codec: VideoCodec) {
        client.setVideoCodec(codec: codec)
    }
    
    override func setAudioCodecImp(codec: AudioCodec) {
        client.setAudioCodec(codec: codec)
    }

    override func stopStreamImp() {
        client.disconnect()
    }
    
    override func startStreamImp(endpoint: String) {
        if videoEncoder.rotation == 90 || videoEncoder.rotation == 270 {
            client.setVideoResolution(width: videoEncoder.height, height: videoEncoder.width)
        } else {
            client.setVideoResolution(width: videoEncoder.width, height: videoEncoder.height)
        }
        client.setFps(fps: videoEncoder.fps)
        client.connect(url: endpoint)
    }
    
    override func onAudioInfoImp(sampleRate: Int, isStereo: Bool) {
        client.setAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
    }
    
    override func getAudioDataImp(frame: Frame) {
        client.sendAudio(buffer: frame.buffer, ts: frame.timeStamp)
    }

    override func getVideoDataImp(frame: Frame) {
        client.sendVideo(buffer: frame.buffer, ts: frame.timeStamp)
    }

    override func onVideoInfoImp(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        client.setVideoInfo(sps: sps, pps: pps, vps: vps)
    }
}
