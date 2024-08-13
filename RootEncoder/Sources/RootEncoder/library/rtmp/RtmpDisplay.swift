//
//  DisplayRtmp.swift
//  RootEncoder
//
//  Created by Pedro  on 24/10/23.
//

import Foundation
import UIKit

public class RtmpDisplay: DisplayBase, StreamClientListenter {

    public func onRequestKeyframe() {
        videoEncoder.forceKeyFrame()
    }
    private var client: RtmpClient!
    private var streamClient: RtmpStreamClient?

    public init(connectChecker: ConnectChecker) {
        client = RtmpClient(connectChecker: connectChecker)
        super.init()
        streamClient = RtmpStreamClient(client: client, listener: self)
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
