//
//  File.swift
//  RootEncoder
//
//  Created by Pedro  on 5/10/24.
//

import Foundation
import AVFoundation
import MetalKit

public class StreamBase {
    
    private var audioEncoder: AudioEncoder!
    internal var videoEncoder: VideoEncoder!
    private(set) var endpoint: String = ""
    private var streaming = false
    private var onPreview = false
    private var fpsListener = FpsListener()
    private let recordController = RecordController()
    private var callback: StreamBaseCallback? = nil
    private(set) public var metalInterface: MetalInterface
    private let videoSource: VideoSource
    private let audioSource: AudioSource
    
    public init(videoSource: VideoSource, audioSource: AudioSource) {
        self.videoSource = videoSource
        self.audioSource = audioSource
        self.metalInterface = MetalStreamInterface()
        initialize()
    }
    
    private func initialize() {
        let callback = createStreamBaseCallbacks()
        self.callback = callback
        videoEncoder = VideoEncoder(callback: callback)
        audioEncoder = AudioEncoder(callback: callback)
    }
    
    func setVideoCodecImp(codec: VideoCodec) {}
    
    func setAudioCodecImp(codec: AudioCodec) {}
    
    func getAudioDataImp(frame: Frame) {}

    func onVideoInfoImp(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {}

    func getVideoDataImp(frame: Frame) {}
}

protocol StreamBaseCallback: GetMicrophoneData, GetCameraData, GetAudioData, GetVideoData, MetalViewCallback {}

extension StreamBase {
    func createStreamBaseCallbacks() -> StreamBaseCallback {
        class StreamBaseCallbackHandler: StreamBaseCallback {
            
            private let streamBase: StreamBase
            
            init(streamBase: StreamBase) {
                self.streamBase = streamBase
            }
            
            func getPcmData(frame: PcmFrame) {
                streamBase.recordController.recordAudio(pcmBuffer: frame.buffer, time: frame.time)
                streamBase.audioEncoder.encodeFrame(frame: frame)
            }

            func getYUVData(from buffer: CMSampleBuffer) {
                streamBase.metalInterface.sendBuffer(buffer: buffer)
            }

            func getVideoData(pixelBuffer: CVPixelBuffer, pts: CMTime) {
                streamBase.recordController.recordVideo(pixelBuffer: pixelBuffer, pts: pts)
                streamBase.videoEncoder.encodeFrame(pixelBuffer: pixelBuffer, pts: pts)
            }
            
            func getAudioData(frame: Frame) {
                streamBase.getAudioDataImp(frame: frame)
            }

            func getVideoData(frame: Frame) {
                streamBase.fpsListener.calculateFps()
                streamBase.getVideoDataImp(frame: frame)
            }

            func onVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
                streamBase.onVideoInfoImp(sps: sps, pps: pps, vps: vps)
            }
        }
        return StreamBaseCallbackHandler(streamBase: self)
    }
}
