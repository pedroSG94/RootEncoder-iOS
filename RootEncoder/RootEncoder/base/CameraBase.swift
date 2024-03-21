//
// Created by Pedro  on 25/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import encoder
import common

public class CameraBase: GetMicrophoneData, GetCameraData, GetAacData, GetH264Data, MetalViewCallback {

    private var microphone: MicrophoneManager!
    private var cameraManager: CameraManager!
    private var audioEncoder: AudioEncoder!
    internal var videoEncoder: VideoEncoder!
    private(set) var endpoint: String = ""
    private var streaming = false
    private var onPreview = false
    private var fpsListener = FpsListener()
    private var metalView: MetalView? = nil
    private var previewResolution = CameraHelper.Resolution.vga640x480
    private let recordController = RecordController()

    public init(view: UIView) {
        cameraManager = CameraManager(cameraView: view, callback: self)
        microphone = MicrophoneManager(callback: self)
        videoEncoder = VideoEncoder(callback: self)
        audioEncoder = AudioEncoder(callback: self)
    }
    
    public init(view: MetalView) {
        self.metalView = view
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
        startEncoders()
        onPreview = true
        streaming = true
        startStreamRtp(endpoint: endpoint)
    }

    private func startEncoders() {
        audioEncoder.start()
        videoEncoder.start()
        microphone.start()
        cameraManager.start()
        metalView?.setCallback(callback: self)
    }
    
    private func stopEncoders() {
        metalView?.setCallback(callback: nil)
        microphone.stop()
        audioEncoder.stop()
        videoEncoder.stop()
    }
    
    public func stopStreamRtp() {}

    public func stopStream() {
        stopEncoders()
        stopStreamRtp()
        endpoint = ""
        streaming = false
    }
    
    public func startRecord(path: URL) {
        recordController.startRecord(path: path)
        startEncoders()
    }

    public func stopRecord() {
        stopEncoders()
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
        let type = switch codec {
        case .H264:
            CodecUtil.H264
        case .H265:
            CodecUtil.H265
        @unknown default:
            CodecUtil.H264
        }
        videoEncoder.setCodec(codec: type)
    }
    
    public func setAudioCodec(codec: common.AudioCodec) {
        setAudioCodecImp(codec: codec)
        recordController.setAudioCodec(codec: codec)
        audioEncoder.codec = codec
    }

    public func setVideoCodecImp(codec: VideoCodec) {}
    
    public func setAudioCodecImp(codec: common.AudioCodec) {}
    
    public func getAacDataRtp(frame: Frame) {}

    public func onSpsPpsVpsRtp(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {}

    public func getH264DataRtp(frame: Frame) {}

    public func getPcmData(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        recordController.recordAudio(buffer: buffer.makeSampleBuffer(time)!)
        audioEncoder.encodeFrame(buffer: buffer)
    }

    public func getYUVData(from buffer: CMSampleBuffer) {
        guard let metalView = metalView else {
            recordController.recordVideo(buffer: buffer)
            videoEncoder.encodeFrame(buffer: buffer)
            return
        }
        metalView.update(buffer: buffer)
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
