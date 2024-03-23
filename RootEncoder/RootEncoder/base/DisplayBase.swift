//
//  DisplayBase.swift
//  RootEncoder
//
//  Created by Pedro  on 24/10/23.
//

import Foundation
import AVFoundation
import UIKit
import encoder
import common

public class DisplayBase: GetMicrophoneData, GetCameraData, GetAacData, GetH264Data {

    private var microphone: MicrophoneManager!
    private var cameraManager: ScreenManager!
    private var audioEncoder: AudioEncoder!
    internal var videoEncoder: VideoEncoder!
    private(set) var endpoint: String = ""
    private var streaming = false
    private var onPreview = false
    private var fpsListener = FpsListener()
    private let recordController = RecordController()

    public init(view: UIView) {
        cameraManager = ScreenManager(cameraView: view, callbackVideo: self, callbackAudio: nil)
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
        return audioEncoder.prepareAudio(inputFormat: microphone.getInputFormat(), sampleRate: Double(sampleRate), channels: UInt32(channels), bitrate: bitrate)
    }

    public func prepareAudio() -> Bool {
        prepareAudio(bitrate: 64 * 1024, sampleRate: 32000, isStereo: true)
    }

    public func prepareVideo(resolution: CameraHelper.Resolution, fps: Int, bitrate: Int, iFrameInterval: Int, rotation: Int = 0) -> Bool {
        var w = resolution.width
        var h = resolution.height
        if (rotation == 90 || rotation == 270) {
            w = resolution.height
            h = resolution.width
        }
        recordController.setVideoFormat(witdh: w, height: h, bitrate: bitrate)
        return videoEncoder.prepareVideo(resolution: resolution, fps: fps, bitrate: bitrate, iFrameInterval: iFrameInterval, rotation: rotation)
    }

    public func prepareVideo() -> Bool {
        prepareVideo(resolution: .fhd1920x1440, fps: 30, bitrate: 1200 * 1024, iFrameInterval: 2, rotation: 0)
    }

    public func setFpsListener(fpsCallback: FpsCallback) {
        fpsListener.setCallback(callback: fpsCallback)
    }

    private func startEncoders() {
        audioEncoder.start()
        videoEncoder.start()
        microphone.start()
        cameraManager.start()
    }
    
    private func stopEncoders() {
        microphone.stop()
        cameraManager.stop()
        audioEncoder.stop()
        videoEncoder.stop()
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
        if (!streaming){
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

    public func startPreview(resolution: CameraHelper.Resolution, facing: CameraHelper.Facing = .BACK) {
        if (!isOnPreview()) {
            cameraManager.start()
            onPreview = true
        }
    }

    public func startPreview() {
        if (!isOnPreview()) {
            cameraManager.start()
            onPreview = true
        }
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
        recordController.recordVideo(buffer: buffer)
        videoEncoder.encodeFrame(buffer: buffer)
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
