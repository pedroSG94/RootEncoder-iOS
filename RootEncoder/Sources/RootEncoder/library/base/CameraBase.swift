//
// Created by Pedro  on 25/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public class CameraBase: GetMicrophoneData, GetCameraData, GetAacData, GetH264Data, MetalViewCallback {

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

    public init(view: UIView) {
        cameraManager = CameraManager(cameraView: view, callback: self)
        microphone = MicrophoneManager(callback: self)
        videoEncoder = VideoEncoder(callback: self)
        audioEncoder = AudioEncoder(callback: self)
    }
    
    public init(view: MetalView) {
        self.metalInterface = view
        cameraManager = CameraManager(callback: self)
        microphone = MicrophoneManager(callback: self)
        videoEncoder = VideoEncoder(callback: self)
        audioEncoder = AudioEncoder(callback: self)
    }

    public func prepareAudioRtp(sampleRate: Int, isStereo: Bool) {}

    public func prepareAudio(bitrate: Int, sampleRate: Int, isStereo: Bool) -> Bool {
        let channels = isStereo ? 2 : 1
        recordController.setAudioFormat(sampleRate: sampleRate, channels: channels, bitrate: bitrate)
        microphone.createMicrophone()
        prepareAudioRtp(sampleRate: sampleRate, isStereo: isStereo)
        return audioEncoder.prepareAudio(inputFormat: microphone.getInputFormat(), sampleRate: Double(sampleRate),
                channels: isStereo ? 2 : 1, bitrate: bitrate)
    }

    public func prepareAudio() -> Bool {
        prepareAudio(bitrate: 64 * 1024, sampleRate: 32000, isStereo: true)
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
        recordController.setVideoFormat(witdh: w, height: h, bitrate: bitrate)
        cameraManager.prepare(resolution: resolution, rotation: rotation)
        return videoEncoder.prepareVideo(resolution: resolution, fps: fps, bitrate: bitrate, iFrameInterval: iFrameInterval, rotation: rotation)
    }

    public func prepareVideo() -> Bool {
        prepareVideo(resolution: .vga640x480, fps: 30, bitrate: 1200 * 1024, iFrameInterval: 2, rotation: CameraHelper.getCameraOrientation())
    }

    public func setFpsListener(fpsCallback: FpsCallback) {
        fpsListener.setCallback(callback: fpsCallback)
    }

    public func startStreamRtp(endpoint: String) {}
        
    public func startStream(endpoint: String) {
        self.endpoint = endpoint
        if (!isRecording()) {
            startEncoders()
        }
        onPreview = true
        streaming = true
        startStreamRtp(endpoint: endpoint)
    }

    private func startEncoders() {
        audioEncoder.start()
        videoEncoder.start()
        microphone.start()
        cameraManager.start()
        metalInterface?.setCallback(callback: self)
    }
    
    private func stopEncoders() {
        metalInterface?.setCallback(callback: nil)
        microphone.stop()
        audioEncoder.stop()
        videoEncoder.stop()
    }
    
    public func stopStreamRtp() {}

    public func stopStream() {
        if (!isRecording()) {
            stopEncoders()
        }
        stopStreamRtp()
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
        startPreview(resolution: CameraHelper.Resolution.vga640x480, facing: CameraHelper.Facing.BACK, rotation: CameraHelper.getCameraOrientation())
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

    public func setVideoCodecImp(codec: VideoCodec) {}
    
    public func setAudioCodecImp(codec: AudioCodec) {}
    
    public func getAacDataRtp(frame: Frame) {}

    public func onSpsPpsVpsRtp(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {}

    public func getH264DataRtp(frame: Frame) {}

    public func getPcmData(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        recordController.recordAudio(buffer: buffer.makeSampleBuffer(time)!)
        audioEncoder.encodeFrame(buffer: buffer)
    }

    public func getYUVData(from buffer: CMSampleBuffer) {
        guard let metalInterface = metalInterface else {
            recordController.recordVideo(buffer: buffer)
            videoEncoder.encodeFrame(buffer: buffer)
            return
        }
        metalInterface.sendBuffer(buffer: buffer)
    }

    public func getVideoData(pixelBuffer: CVPixelBuffer, pts: CMTime) {
        recordController.recordVideo(pixelBuffer: pixelBuffer, pts: pts)
        videoEncoder.encodeFrame(pixelBuffer: pixelBuffer, pts: pts)
    }
    
    public func getAacData(frame: Frame) {
        getAacDataRtp(frame: frame)
    }

    public func getH264Data(frame: Frame) {
        fpsListener.calculateFps()
        getH264DataRtp(frame: frame)
    }

    public func getSpsAndPps(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        onSpsPpsVpsRtp(sps: sps, pps: pps, vps: vps)
    }
}
