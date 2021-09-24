//
// Created by Pedro  on 21/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public class RtspCamera: GetMicrophoneData, GetCameraData, GetAacData, GetH264Data {

    private(set) var client: RtspClient!
    private(set) var microphone: MicrophoneManager!
    private(set) var cameraManager: CameraManager!
    private(set) var audioEncoder: AudioEncoder!
    private(set) var videoEncoder: VideoEncoder!
    private var endpoint: String = ""
    private var streaming = false
    private var onPreview = false

    public init(view: UIView, connectChecker: ConnectCheckerRtsp) {
        client = RtspClient(connectCheckerRtsp: connectChecker)
        cameraManager = CameraManager(cameraView: view, callback: self)
        microphone = MicrophoneManager(callback: self)
        videoEncoder = VideoEncoder(callback: self)
        audioEncoder = AudioEncoder(callback: self)
    }

    public func prepareAudio(bitrate: Int, sampleRate: Int, isStereo: Bool) -> Bool {
        microphone.createMicrophone()
        client?.setAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
        return audioEncoder.prepareAudio(inputFormat: microphone.getInputFormat(), sampleRate: Double(sampleRate),
                channels: isStereo ? 2 : 1, bitrate: bitrate)
    }

    public func prepareAudio() -> Bool {
        prepareAudio(bitrate: 64 * 1024, sampleRate: 32000, isStereo: true)
    }

    public func prepareVideo(resolution: CameraHelper.Resolution, fps: Int, bitrate: Int, iFrameInterval: Int) -> Bool {
        cameraManager.prepare(resolution: resolution)
        return videoEncoder.prepareVideo(resolution: resolution, fps: fps, bitrate: bitrate, iFrameInterval: iFrameInterval)
    }

    public func prepareVideo() -> Bool {
        prepareVideo(resolution: .vga640x480, fps: 30, bitrate: 1200 * 1024, iFrameInterval: 2)
    }

    public func startStream(endpoint: String) {
        self.endpoint = endpoint
        microphone.start()
        cameraManager.start()
        onPreview = true
        streaming = true
    }

    public func stopStream() {
        microphone.stop()
        cameraManager.stopSend()
        audioEncoder.stop()
        videoEncoder.stop()
        client.disconnect()
        endpoint = ""
        streaming = false
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

    public func startPreview(resolution: CameraHelper.Resolution) {
        cameraManager.start(onPreview: true, resolution: resolution)
        onPreview = true
    }

    public func startPreview() {
        cameraManager.start(onPreview: true)
        onPreview = true
    }

    public func stopPreview() {
        cameraManager.stop()
        onPreview = false
    }

    public func getPcmData(buffer: AVAudioPCMBuffer) {
        audioEncoder.encodeFrame(buffer: buffer)
    }

    public func getYUVData(from buffer: CMSampleBuffer) {
        videoEncoder.encodeFrame(buffer: buffer)
    }

    public func getAacData(frame: Frame) {
        client.sendAudio(frame: frame)
    }

    public func getH264Data(frame: Frame) {
        client.sendVideo(frame: frame)
    }

    public func getSpsAndPps(sps: Array<UInt8>, pps: Array<UInt8>) {
        client.setVideoInfo(sps: sps, pps: pps, vps: nil)
        client.connect(url: endpoint)
    }
}
