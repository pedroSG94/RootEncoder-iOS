//
//  File.swift
//  
//
//  Created by Pedro  on 26/8/24.
//

import Foundation

public class GenericDisplay: DisplayBase {

    private let rtmpClient: RtmpClient
    private let rtspClient: RtspClient
    private let connectChecker: ConnectChecker
    private var streamClient: GenericStreamClient?
    private var connectedType = ClientType.NONE

    public init(connectChecker: ConnectChecker) {
        self.connectChecker = connectChecker
        rtmpClient = RtmpClient(connectChecker: connectChecker)
        rtspClient = RtspClient(connectChecker: connectChecker)
        super.init()
        streamClient = GenericStreamClient(
            rtmpClient: RtmpStreamClient(client: rtmpClient, listener: videoEncoder.createStreamClientListener()),
            rtspClient: RtspStreamClient(client: rtspClient, listener: videoEncoder.createStreamClientListener())
        )
    }
    
    public func getStreamClient() -> GenericStreamClient {
        return streamClient!
    }
    
    override func setVideoCodecImp(codec: VideoCodec) {
        rtmpClient.setVideoCodec(codec: codec)
        rtspClient.setVideoCodec(codec: codec)
    }
    
    override func setAudioCodecImp(codec: AudioCodec) {
        rtmpClient.setAudioCodec(codec: codec)
        rtspClient.setAudioCodec(codec: codec)
    }
    
    override func stopStreamImp() {
        switch connectedType {
        case .RTMP:
            rtmpClient.disconnect()
        case .RTSP:
            rtspClient.disconnect()
        case .NONE:
            break
        }
        connectedType = ClientType.NONE
    }
    
    override func startStreamImp(endpoint: String) {
        streamClient?.connecting(url: endpoint)
        if endpoint.lowercased().hasPrefix("rtmp") {
            connectedType = ClientType.RTMP
            if videoEncoder.rotation == 90 || videoEncoder.rotation == 270 {
                rtmpClient.setVideoResolution(width: videoEncoder.height, height: videoEncoder.width)
            } else {
                rtmpClient.setVideoResolution(width: videoEncoder.width, height: videoEncoder.height)
            }
            rtmpClient.setFps(fps: videoEncoder.fps)
            rtmpClient.connect(url: endpoint)
        } else if endpoint.lowercased().hasPrefix("rtsp") {
            connectedType = ClientType.RTSP
            rtspClient.connect(url: endpoint)
        } else {
            connectChecker.onConnectionFailed(reason: "Unsupported protocol. Only support rtmp and rtsp")
        }
    }
    
    override func onAudioInfoImp(sampleRate: Int, isStereo: Bool) {
        rtmpClient.setAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
        rtspClient.setAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
    }
    
    override func getAudioDataImp(frame: Frame) {
        switch connectedType {
        case .RTMP:
            rtmpClient.sendAudio(buffer: frame.buffer, ts: frame.timeStamp)
        case .RTSP:
            rtspClient.sendAudio(buffer: frame.buffer, ts: frame.timeStamp)
        case .NONE:
            break
        }
    }

    override func getVideoDataImp(frame: Frame) {
        switch connectedType {
        case .RTMP:
            rtmpClient.sendVideo(buffer: frame.buffer, ts: frame.timeStamp)
        case .RTSP:
            rtspClient.sendVideo(buffer: frame.buffer, ts: frame.timeStamp)
        case .NONE:
            break
        }
    }

    override func onVideoInfoImp(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        rtmpClient.setVideoInfo(sps: sps, pps: pps, vps: vps)
        rtspClient.setVideoInfo(sps: sps, pps: pps, vps: vps)
    }
}
