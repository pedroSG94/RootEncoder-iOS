//
// Created by Pedro  on 17/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class RtspStream: StreamBase {
    
    private let client: RtspClient
    private var streamClient: RtspStreamClient?
    
    public init(connectChecker: ConnectChecker) {
        client = RtspClient(connectChecker: connectChecker)
        super.init(videoSource: CameraSource(), audioSource: MicrophoneSource())
        streamClient = RtspStreamClient(client: client, listener: videoEncoder.createStreamClientListener())
    }
    
    public func getStreamClient() -> RtspStreamClient {
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
        client.connect(url: endpoint)
    }
    
    override func onAudioInfoImp(sampleRate: Int, isStereo: Bool) {
        client.setAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
    }
    
    override func onVideoInfoImp(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        client.setVideoInfo(sps: sps, pps: pps, vps: vps)
    }
    
    override func getAudioDataImp(frame: Frame) {
        client.sendAudio(buffer: frame.buffer, ts: frame.timeStamp)
    }

    override func getVideoDataImp(frame: Frame) {
        client.sendVideo(buffer: frame.buffer, ts: frame.timeStamp)
    }
}
