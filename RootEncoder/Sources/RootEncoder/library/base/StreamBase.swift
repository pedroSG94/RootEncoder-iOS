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
    private(set) public var metalInterface: MetalStreamInterface
    private var videoSource: VideoSource
    private var audioSource: AudioSource
    
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
    
    public func prepareVideo(width: Int, height: Int, bitrate: Int, fps: Int = 30, iFrameInterval: Int = 2, rotation: Int = 0) -> Bool {
        if recordController.isRecording() || streaming {
            //TODO throw error
        }
        let videoResult = videoSource.create(width: width, height: height, fps: fps, rotation: rotation)
        if videoResult {
            metalInterface.setOrientation(orientation: rotation)
            if rotation == 0 || rotation == 180 {
                metalInterface.setEncoderSize(width: width, height: height)
            } else {
                metalInterface.setEncoderSize(width: height, height: width)
            }
            metalInterface.setForceFps(fps: fps)
            return videoEncoder.prepareVideo(width: width, height: height, fps: fps, bitrate: bitrate, iFrameInterval: iFrameInterval, rotation: rotation)
        }
        return false
    }
    
    public func prepareAudio(sampleRate: Int, isStereo: Bool, bitrate: Int) -> Bool {
        if recordController.isRecording() || streaming {
            //TODO throw error
        }
        let audioResult = audioSource.create(sampleRate: sampleRate, isStereo: isStereo)
        if audioResult {
            onAudioInfoImp(sampleRate: sampleRate, isStereo: isStereo)
            let channels: UInt32 = if isStereo { 2 } else { 1 }
            return audioEncoder.prepareAudio(sampleRate: Double(sampleRate), channels: channels, bitrate: bitrate)
        }
        return false
    }
    
    public func startStream(endpoint: String) {
        if streaming {
            //TODO throw error
        }
        streaming = true
        startStreamImp(endpoint: endpoint)
        if !recordController.isRecording() {
            startSources()
        } else {
            requestKeyframe()
        }
    }
    
    @discardableResult
    public func stopStream() -> Bool {
        streaming = false
        stopStreamImp()
        if !recordController.isRecording() {
            stopSources()
            return prepareEncoders()
        }
        return true
    }
    
    public func startRecord(path: URL) {
        if recordController.isRecording() {
            //TODO throw error
        }
        recordController.startRecord(path: path)
        if !streaming {
            startSources()
        } else {
            requestKeyframe()
        }
    }
    
    public func stopRecord() -> Bool {
        recordController.stopRecord()
        if !streaming {
            stopSources()
            return prepareEncoders()
        }
        return true
    }
    
    public func startPreview(view: MTKView) {
        guard let callback = callback else { return }
        onPreview = true
        metalInterface.setCallback(callback: callback)
        metalInterface.attachPreview(mtkView: view)
        if !videoSource.isRunning() {
            videoSource.start(metalInterface: metalInterface)
        }
    }
    
    public func stopPreview() {
        onPreview = false
        if !streaming && recordController.isRecording() {
            videoSource.stop()
        }
        metalInterface.deAttachPreview()
        if !streaming && recordController.isRecording() {
            metalInterface.setCallback(callback: nil)
        }
    }
    
    public func changeVideoSource(source: VideoSource) {
        let wasRunning = videoSource.isRunning()
        let wasCreated = videoSource.created()
        if wasCreated {
            let _ = source.create(width: videoEncoder.width, height: videoEncoder.height, fps: videoEncoder.fps, rotation: videoEncoder.rotation)
        }
        videoSource.stop()
        videoSource.release()
        if wasRunning { source.start(metalInterface: metalInterface) }
        videoSource = source
    }
    
    public func changeAudioSource(source: AudioSource) {
        guard let callback = callback else { return }
        let wasRunning = audioSource.isRunning()
        let wasCreated = audioSource.created()
        if wasCreated {
            let isStereo: Bool = if audioEncoder.channels == 1 { false } else { true }
            let _ = source.create(sampleRate: Int(audioEncoder.sampleRate), isStereo: isStereo)
        }
        audioSource.stop()
        audioSource.release()
        if wasRunning { source.start(calback: callback) }
        audioSource = source
    }
    
    public func release() {
        if streaming { stopStream() }
        if recordController.isRecording() { recordController.stopRecord() }
        if onPreview { stopPreview() }
        stopSources()
        videoSource.release()
        audioSource.release()
    }
    
    private func startSources() {
        guard let callback = callback else { return }
        metalInterface.setCallback(callback: callback)
        if !videoSource.isRunning() {
            videoSource.start(metalInterface: metalInterface)
        }
        if !audioSource.isRunning() {
            audioSource.start(calback: callback)
        }
        videoEncoder.start()
        audioEncoder.start()
    }
    
    private func stopSources() {
        if !onPreview {
            videoSource.stop()
            metalInterface.setCallback(callback: nil)
        }
        audioSource.stop()
        videoEncoder.stop()
        audioEncoder.stop()
    }
    
    private func prepareEncoders() -> Bool {
        return videoEncoder.prepareVideo() && audioEncoder.prepareAudio()
    }
    
    public func requestKeyframe() {
        videoEncoder.forceKeyFrame()
    }
    
    func startStreamImp(endpoint: String) {}
    func stopStreamImp() {}
    func onAudioInfoImp(sampleRate: Int, isStereo: Bool) {}
    func onVideoInfoImp(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {}
    
    func setVideoCodecImp(codec: VideoCodec) {}
    func setAudioCodecImp(codec: AudioCodec) {}
    func getAudioDataImp(frame: Frame) {}
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
