//
//  File.swift
//  
//
//  Created by Pedro  on 16/7/24.
//

import Foundation
import AVFoundation
import UIKit

/*
 * Support multiple streams in RTMP and RTMP at same time.
 * You must set the same number of ConnectChecker that you want use.
 *
 * For example. 2 RTMP and 1 RTSP:
 * stream1, stream2, stream3 (stream1 and stream2 are ConnectChecker for RTMP. stream3 is ConnectChecker for RTSP)
 *
 * let arrayRtmp: [ConnectChecker] = [stream1, stream2]
 * let arrayRtsp: [ConnectChecker] = [stream3]
 * let multiCamera = MultiCamera(uiView, arrayRtmp, arrayRtsp);
 *
 * You can set an empty array or nil if you don't want use a protocol
 * MultiCamera(uiView, arrayRtmp, nil); //RTSP protocol is not used
 *
 * In order to use start, stop and other calls you must send type of stream and index to execute it.
 * Example (using previous example interfaces):
 *
 * multiCamera.startStream(MultiType.RTMP, 1, myendpoint); //stream2 is started
 * multiCamera.stopStream(MultiType.RTSP, 0); //stream3 is stopped
 * multiCamera.retry(RtpType.RTMP, 0, delay, reason, backupUrl) //retry stream1
 *
 * NOTE:
 * If you call this methods nothing is executed:
 *
 * multiCamera.startStream(endpoint);
 * multiCamera.stopStream();
 * multiCamera.retry(delay, reason, backUpUrl);
 *
 * The rest of methods without MultiType and index means that you will execute that command in all streams.
 * Read class code if you need info about any method.
 */
public class MultiCamera: CameraBase {
    
    private var rtmpClients = Array<RtmpClient>()
    private var rtspClients = Array<RtspClient>()
    
    public init(view: UIView, connectCheckerRtmpList: Array<ConnectChecker>?, connectCheckerRtspList: Array<ConnectChecker>?) {
        for i in connectCheckerRtmpList ?? [] {
            rtmpClients.append(RtmpClient(connectChecker: i))
        }
        for i in connectCheckerRtspList ?? [] {
            rtspClients.append(RtspClient(connectChecker: i))
        }
        super.init(view: view)
    }

    public init(view: MetalView, connectCheckerRtmpList: Array<ConnectChecker>?, connectCheckerRtspList: Array<ConnectChecker>?) {
        for i in connectCheckerRtmpList ?? [] {
            rtmpClients.append(RtmpClient(connectChecker: i))
        }
        for i in connectCheckerRtspList ?? [] {
            rtspClients.append(RtspClient(connectChecker: i))
        }
        super.init(view: view)
    }
    
    public func setAuth(user: String, password: String) {
        for rtmp in rtmpClients {
            rtmp.setAuth(user: user, password: password)
        }
        for rtsp in rtspClients {
            rtsp.setAuth(user: user, password: password)
        }
    }
    
    public func setAuth(type: MultiType, index: Int, user: String, password: String) {
        if type == MultiType.RTMP {
            let client = rtmpClients[index]
            client.setAuth(user: user, password: password)
        } else {
            let client = rtspClients[index]
            client.setAuth(user: user, password: password)
        }
    }
    
    public override func setVideoCodecImp(codec: VideoCodec) {
        for rtmp in rtmpClients {
            rtmp.setVideoCodec(codec: codec)
        }
        for rtsp in rtspClients {
            rtsp.setVideoCodec(codec: codec)
        }
    }
    
    public override func setAudioCodecImp(codec: AudioCodec) {
        for rtmp in rtmpClients {
            rtmp.setAudioCodec(codec: codec)
        }
        for rtsp in rtspClients {
            rtsp.setAudioCodec(codec: codec)
        }
    }
    
    public func setLogs(enabled: Bool) {
        for rtmp in rtmpClients {
            rtmp.setLogs(enabled: enabled)
        }
        for rtsp in rtspClients {
            rtsp.setLogs(enabled: enabled)
        }
    }
    
    public func setRetries(reTries: Int) {
        for rtmp in rtmpClients {
            rtmp.setRetries(reTries: reTries)
        }
        for rtsp in rtspClients {
            rtsp.setRetries(reTries: reTries)
        }
    }
    
    public func retry(type: MultiType, index: Int, delay: Int, reason: String, backUrl: String? = nil) -> Bool {
        if type == MultiType.RTMP {
            let client = rtmpClients[index]
            let result = client.shouldRetry(reason: reason)
            if (result) {
                videoEncoder.forceKeyFrame()
                client.reconnect(delay: delay, backupUrl: backUrl)
            }
            return result
        } else {
            let client = rtspClients[index]
            let result = client.shouldRetry(reason: reason)
            if (result) {
                videoEncoder.forceKeyFrame()
                client.reconnect(delay: delay, backupUrl: backUrl)
            }
            return result
        }
    }
    
    public func stopStream(type: MultiType, index: Int) {
        var shouldStopEncoder = true
        if type == MultiType.RTMP {
            let client = rtmpClients[index]
            client.disconnect()
        } else {
            let client = rtspClients[index]
            client.disconnect()
        }
        for rtmp in rtmpClients {
            if rtmp.isStreaming {
                shouldStopEncoder = false
                break
            }
        }
        for rtsp in rtspClients {
            if rtsp.isStreaming() {
                shouldStopEncoder = false
                break
            }
        }
        if shouldStopEncoder {
            super.stopStream()
        }
    }
    
    public func startStream(type: MultiType, index: Int, endpoint: String) {
        var shouldStarEncoder = true
        for rtmp in rtmpClients {
            if rtmp.isStreaming {
                shouldStarEncoder = false
                break
            }
        }
        for rtsp in rtspClients {
            if rtsp.isStreaming() {
                shouldStarEncoder = false
                break
            }
        }
        if shouldStarEncoder {
            super.startStream(endpoint: "")
        }
        if type == MultiType.RTMP {
            let client = rtmpClients[index]
            if videoEncoder.rotation == 90 || videoEncoder.rotation == 270 {
                client.setVideoResolution(width: videoEncoder.height, height: videoEncoder.width)
            } else {
                client.setVideoResolution(width: videoEncoder.width, height: videoEncoder.height)
            }
            client.setFps(fps: videoEncoder.fps)
            client.connect(url: endpoint)
        } else {
            let client = rtspClients[index]
            client.connect(url: endpoint)
        }
    }
    
    public override func stopStreamRtp() {
        
    }
    
    public override func startStreamRtp(endpoint: String) {
        
    }
    
    public override func prepareAudioRtp(sampleRate: Int, isStereo: Bool) {
        super.prepareAudioRtp(sampleRate: sampleRate, isStereo: isStereo)
        for rtmp in rtmpClients {
            rtmp.setAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
        }
        for rtsp in rtspClients {
            rtsp.setAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
        }
    }
    
    public override func getAacDataRtp(frame: Frame) {
        for rtmp in rtmpClients {
            rtmp.sendAudio(buffer: frame.buffer!, ts: frame.timeStamp!)
        }
        for rtsp in rtspClients {
            rtsp.sendAudio(buffer: frame.buffer!, ts: frame.timeStamp!)
        }
    }

    public override func getH264DataRtp(frame: Frame) {
        for rtmp in rtmpClients {
            rtmp.sendVideo(buffer: frame.buffer!, ts: frame.timeStamp!)
        }
        for rtsp in rtspClients {
            rtsp.sendVideo(buffer: frame.buffer!, ts: frame.timeStamp!)
        }
    }

    public override func onSpsPpsVpsRtp(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        for rtmp in rtmpClients {
            rtmp.setVideoInfo(sps: sps, pps: pps, vps: vps)
        }
        for rtsp in rtspClients {
            rtsp.setVideoInfo(sps: sps, pps: pps, vps: vps)
        }
    }
}
