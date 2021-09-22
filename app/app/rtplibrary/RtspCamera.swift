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

    public init(view: UIView, connectChecker: ConnectCheckerRtsp) {
        client = RtspClient(connectCheckerRtsp: connectChecker)
        cameraManager = CameraManager(cameraView: view, callback: self)
        microphone = MicrophoneManager(callback: self)
        videoEncoder = VideoEncoder(callback: self)
        audioEncoder = AudioEncoder(callback: self)
    }

    public func prepareAudio() -> Bool {
        microphone.createMicrophone()
        client?.setAudioInfo(sampleRate: 44100, isStereo: false)
        return audioEncoder.prepareAudio(inputFormat: microphone.getInputFormat(), sampleRate: 44100, channels: 2, bitrate: 64 * 1000)
    }

    public func prepareVideo() -> Bool {
        videoEncoder.prepareVideo()
    }

    public func startStream(endpoint: String) {
        self.endpoint = endpoint
        microphone.start()
        cameraManager.start()
        streaming = true
    }

    public func stopStream() {
        microphone.stop()
        cameraManager.stop()
        audioEncoder.stop()
        videoEncoder.stop()
        client.disconnect()
        endpoint = ""
        streaming = false
    }

    public func isStreaming() -> Bool {
        streaming
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