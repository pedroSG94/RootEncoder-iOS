//
// Created by Pedro  on 21/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public class RtspCamera: CameraBase, StreamClientListenter {

    public func onRequestKeyframe() {
        videoEncoder.forceKeyFrame()
    }
    private var client: RtspClient!
    private var streamClient: RtspStreamClient?

    public init(view: UIView, connectChecker: ConnectChecker) {
        client = RtspClient(connectChecker: connectChecker)
        super.init(view: view)
        streamClient = RtspStreamClient(client: client, listener: self)
    }

    public init(view: MetalView, connectChecker: ConnectChecker) {
        client = RtspClient(connectChecker: connectChecker)
        super.init(view: view)
        streamClient = RtspStreamClient(client: client, listener: self)
    }
    
    public func getStreamClient() -> RtspStreamClient {
        return streamClient!
    }
    
    public override func setVideoCodecImp(codec: VideoCodec) {
        client.setVideoCodec(codec: codec)
    }
    
    public override func setAudioCodecImp(codec: AudioCodec) {
        client.setAudioCodec(codec: codec)
    }

    public override func stopStreamImp() {
        client.disconnect()
    }

    public override func startStreamImp(endpoint: String) {
        client.connect(url: endpoint)
    }
    
    public override func onAudioInfoImp(sampleRate: Int, isStereo: Bool) {
        client.setAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
    }
    
    public override func getAudioDataImp(frame: Frame) {
        client.sendAudio(buffer: frame.buffer, ts: frame.timeStamp)
    }

    public override func getVideoDataImp(frame: Frame) {
        client.sendVideo(buffer: frame.buffer, ts: frame.timeStamp)
    }

    public override func onVideoInfoImp(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        client.setVideoInfo(sps: sps, pps: pps, vps: vps)
    }
}
