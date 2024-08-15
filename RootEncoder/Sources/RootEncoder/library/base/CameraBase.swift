//
// Created by Pedro  on 25/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public class CameraBase {

    private var microphone: MicrophoneManager!
    private var cameraManager: CameraManager!
    private var audioEncoder: AudioEncoder!
    internal var videoEncoder: VideoEncoder!
    private(set) var endpoint: String = ""
    private var streaming = false
    private var onPreview = false
    private var fpsListener = FpsListener()
    private var previewResolution = CameraHelper.Resolution.vga640x480
    private let recordController = RecordController()
    private(set) public var metalInterface: MetalInterface? = nil
    private var callback: CameraBaseCallback? = nil

    public init(view: UIView) {
        let callback = createCameraBaseCallbacks()
        self.callback = callback
        cameraManager = CameraManager(cameraView: view, callback: callback)
        microphone = MicrophoneManager(callback: callback)
        videoEncoder = VideoEncoder(callback: callback)
        audioEncoder = AudioEncoder(callback: callback)
    }
    
    public init(view: MetalView) {
        self.metalInterface = view
        let callback = createCameraBaseCallbacks()
        self.callback = callback
        cameraManager = CameraManager(callback: callback)
        microphone = MicrophoneManager(callback: callback)
        videoEncoder = VideoEncoder(callback: callback)
        audioEncoder = AudioEncoder(callback: callback)
    }

    func onAudioInfoImp(sampleRate: Int, isStereo: Bool) {}

    public func prepareAudio(bitrate: Int, sampleRate: Int, isStereo: Bool) -> Bool {
        let channels = isStereo ? 2 : 1
        recordController.setAudioFormat(sampleRate: sampleRate, channels: channels, bitrate: bitrate)
        let createResult = microphone.createMicrophone()
        if !createResult {
            return false
        }
        onAudioInfoImp(sampleRate: sampleRate, isStereo: isStereo)
        return audioEncoder.prepareAudio(sampleRate: Double(sampleRate), channels: isStereo ? 2 : 1, bitrate: bitrate)
    }

    public func prepareAudio() -> Bool {
        prepareAudio(bitrate: 128 * 1024, sampleRate: 32000, isStereo: true)
    }

    public func prepareVideo(resolution: CameraHelper.Resolution, fps: Int, bitrate: Int, iFrameInterval: Int, rotation: Int) -> Bool {
        if (previewResolution != resolution || rotation != cameraManager.rotation) {
            cameraManager.stop()
        }
        var w = resolution.width
        var h = resolution.height
        if (rotation == 90 || rotation == 270) {
            w = resolution.height
            h = resolution.width
        }
        metalInterface?.setForceFps(fps: fps)
        recordController.setVideoFormat(witdh: w, height: h, bitrate: bitrate)
        cameraManager.prepare(resolution: resolution, fps: fps, rotation: rotation)
        return videoEncoder.prepareVideo(resolution: resolution, fps: fps, bitrate: bitrate, iFrameInterval: iFrameInterval, rotation: rotation)
    }

    public func prepareVideo() -> Bool {
        prepareVideo(resolution: .vga640x480, fps: 30, bitrate: 1200 * 1024, iFrameInterval: 2, rotation: CameraHelper.getCameraOrientation())
    }

    public func setFpsListener(fpsCallback: FpsCallback) {
        fpsListener.setCallback(callback: fpsCallback)
    }

    func startStreamImp(endpoint: String) {}
        
    public func startStream(endpoint: String) {
        self.endpoint = endpoint
        if (!isRecording()) {
            startEncoders()
        }
        onPreview = true
        streaming = true
        startStreamImp(endpoint: endpoint)
    }

    private func startEncoders() {
        audioEncoder.start()
        videoEncoder.start()
        microphone.start()
        cameraManager.start()
        metalInterface?.setCallback(callback: callback)
    }
    
    private func stopEncoders() {
        metalInterface?.setCallback(callback: nil)
        microphone.stop()
        audioEncoder.stop()
        videoEncoder.stop()
    }
    
    func stopStreamImp() {}

    public func stopStream() {
        if (!isRecording()) {
            stopEncoders()
        }
        stopStreamImp()
        endpoint = ""
        streaming = false
    }
    
    public func startRecord(path: URL) {
        recordController.startRecord(path: path)
        if (!streaming) {
            startEncoders()
        }
    }

    public func stopRecord() {
        if (!streaming) {
            stopEncoders()
        }
        recordController.stopRecord()
    }
    
    public func isRecording() -> Bool {
        return recordController.isRecording()
    }
    
    public func isStreaming() -> Bool {
        streaming
    }

    public func isOnPreview() -> Bool {
        onPreview
    }

    public func switchCamera() {
        cameraManager.switchCamera()
    }
    
    public func isMuted() -> Bool {
        return microphone.isMuted()
    }
    
    public func mute() {
        microphone.mute()
    }
    
    public func unmute() {
        microphone.unmute()
    }

    public func startPreview(resolution: CameraHelper.Resolution, facing: CameraHelper.Facing = .BACK, rotation: Int) {
        if (!isOnPreview()) {
            cameraManager.start(facing: facing, resolution: resolution, rotation: rotation)
            previewResolution = resolution
            onPreview = true
        }
    }

    public func startPreview() {
        startPreview(resolution: .vga640x480, facing: CameraHelper.Facing.BACK, rotation: CameraHelper.getCameraOrientation())
    }

    public func stopPreview() {
        if (!isStreaming() && isOnPreview()) {
            cameraManager.stop()
            onPreview = false
        }
    }
    
    public func setVideoCodec(codec: VideoCodec) {
        setVideoCodecImp(codec: codec)
        recordController.setVideoCodec(codec: codec)
        videoEncoder.setCodec(codec: codec)
    }
    
    public func setAudioCodec(codec: AudioCodec) {
        setAudioCodecImp(codec: codec)
        recordController.setAudioCodec(codec: codec)
        audioEncoder.setCodec(codec: codec)
    }

    func setVideoCodecImp(codec: VideoCodec) {}
    
    func setAudioCodecImp(codec: AudioCodec) {}
    
    func getAudioDataImp(frame: Frame) {}

    func onVideoInfoImp(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {}

    func getVideoDataImp(frame: Frame) {}
}

protocol CameraBaseCallback: GetMicrophoneData, GetCameraData, GetAudioData, GetVideoData, MetalViewCallback {}

extension CameraBase {
    func createCameraBaseCallbacks() -> CameraBaseCallback {
        class CameraBaseCallbackHandler: CameraBaseCallback {
            
            private let cameraBase: CameraBase
            
            init(cameraBase: CameraBase) {
                self.cameraBase = cameraBase
            }
            
            func getPcmData(frame: PcmFrame) {
                cameraBase.recordController.recordAudio(pcmBuffer: frame.buffer, time: frame.time)
                cameraBase.audioEncoder.encodeFrame(frame: frame)
            }

            func getYUVData(from buffer: CMSampleBuffer) {
                guard let metalInterface = cameraBase.metalInterface else {
                    cameraBase.recordController.recordVideo(buffer: buffer)
                    cameraBase.videoEncoder.encodeFrame(buffer: buffer)
                    return
                }
                metalInterface.sendBuffer(buffer: buffer)
            }

            func getVideoData(pixelBuffer: CVPixelBuffer, pts: CMTime) {
                cameraBase.recordController.recordVideo(pixelBuffer: pixelBuffer, pts: pts)
                cameraBase.videoEncoder.encodeFrame(pixelBuffer: pixelBuffer, pts: pts)
            }
            
            func getAudioData(frame: Frame) {
                cameraBase.getAudioDataImp(frame: frame)
            }

            func getVideoData(frame: Frame) {
                cameraBase.fpsListener.calculateFps()
                cameraBase.getVideoDataImp(frame: frame)
            }

            func onVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
                cameraBase.onVideoInfoImp(sps: sps, pps: pps, vps: vps)
            }
        }
        return CameraBaseCallbackHandler(cameraBase: self)
    }
    
    public func getCameraManager() -> CameraManager {
        cameraManager
    }
    
}
