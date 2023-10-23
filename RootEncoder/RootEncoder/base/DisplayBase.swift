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

public class DisplayBase: GetMicrophoneData, GetCameraData, GetAacData, GetH264Data {

    private var microphone: MicrophoneManager!
    private var cameraManager: ScreenManager!
    private var audioEncoder: AudioEncoder!
    internal var videoEncoder: VideoEncoder!
    private(set) var endpoint: String = ""
    private var streaming = false
    private var onPreview = false
    private var fpsListener = FpsListener()

    public init(view: UIView) {
        cameraManager = ScreenManager(cameraView: view, callback: self)
        microphone = MicrophoneManager(callback: self)
        videoEncoder = VideoEncoder(callback: self)
        audioEncoder = AudioEncoder(callback: self)
    }

    public func prepareAudioRtp(sampleRate: Int, isStereo: Bool) {}

    public func prepareAudio(bitrate: Int, sampleRate: Int, isStereo: Bool) -> Bool {
        microphone.createMicrophone()
        prepareAudioRtp(sampleRate: sampleRate, isStereo: isStereo)
        return audioEncoder.prepareAudio(inputFormat: microphone.getInputFormat(), sampleRate: Double(sampleRate),
                channels: isStereo ? 2 : 1, bitrate: bitrate)
    }

    public func prepareAudio() -> Bool {
        prepareAudio(bitrate: 64 * 1024, sampleRate: 32000, isStereo: true)
    }

    public func prepareVideo(resolution: CameraHelper.Resolution, fps: Int, bitrate: Int, iFrameInterval: Int) -> Bool {
        return videoEncoder.prepareVideo(resolution: resolution, fps: fps, bitrate: bitrate, iFrameInterval: iFrameInterval)
    }

    public func prepareVideo() -> Bool {
        prepareVideo(resolution: .fhd1920x1440, fps: 30, bitrate: 1200 * 1024, iFrameInterval: 2)
    }

    public func setFpsListener(fpsCallback: FpsCallback) {
        fpsListener.setCallback(callback: fpsCallback)
    }

    public func startStreamRtp(endpoint: String) {}
        
    public func startStream(endpoint: String) {
        self.endpoint = endpoint
        audioEncoder.start()
        videoEncoder.start()
        microphone.start()
        cameraManager.start()
        onPreview = true
        streaming = true
        startStreamRtp(endpoint: endpoint)
    }

    public func stopStreamRtp() {}

    public func stopStream() {
        microphone.stop()
        cameraManager.stop()
        audioEncoder.stop()
        videoEncoder.stop()
        stopStreamRtp()
        endpoint = ""
        streaming = false
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

    public func getAacDataRtp(frame: Frame) {}

    public func onSpsPpsVpsRtp(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {}

    public func getH264DataRtp(frame: Frame) {}

    public func getPcmData(buffer: AVAudioPCMBuffer) {
        audioEncoder.encodeFrame(buffer: buffer)
    }

    public func getYUVData(from buffer: CMSampleBuffer) {
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
