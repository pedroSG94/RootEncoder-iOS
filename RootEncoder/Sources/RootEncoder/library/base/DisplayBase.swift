//
//  DisplayBase.swift
//  RootEncoder
//
//  Created by Pedro  on 24/10/23.
//

import Foundation
import AVFoundation
import UIKit

public class DisplayBase: GetMicrophoneData, GetCameraData, GetAacData, GetH264Data {

    private var microphone: MicrophoneManager!
    private var screenManager: ScreenManager!
    private var audioEncoder: AudioEncoder!
    internal var videoEncoder: VideoEncoder!
    private(set) var endpoint: String = ""
    private var streaming = false
    private var onPreview = false
    private var fpsListener = FpsListener()
    private let recordController = RecordController()

    public init() {
        screenManager = ScreenManager(callbackVideo: self, callbackAudio: nil)
        microphone = MicrophoneManager(callback: self)
        videoEncoder = VideoEncoder(callback: self)
        audioEncoder = AudioEncoder(callback: self)
    }

    public func prepareAudioRtp(sampleRate: Int, isStereo: Bool) {}

    public func prepareAudio(bitrate: Int, sampleRate: Int, isStereo: Bool) -> Bool {
        let channels = isStereo ? 2 : 1
        recordController.setAudioFormat(sampleRate: sampleRate, channels: channels, bitrate: bitrate)
        let createResult = microphone.createMicrophone()
        if !createResult {
            return false
        }
        prepareAudioRtp(sampleRate: sampleRate, isStereo: isStereo)
        return audioEncoder.prepareAudio(sampleRate: Double(sampleRate), channels: UInt32(channels), bitrate: bitrate)
    }

    public func prepareAudio() -> Bool {
        prepareAudio(bitrate: 128 * 1024, sampleRate: 44100, isStereo: true)
    }

    public func prepareVideo(fps: Int, bitrate: Int, iFrameInterval: Int, rotation: Int = 0) -> Bool {
        let w = screenManager.getWidth()
        let h = screenManager.getHeight()
        recordController.setVideoFormat(witdh: w, height: h, bitrate: bitrate)
        return videoEncoder.prepareVideo(width: w, height: h, fps: fps, bitrate: bitrate, iFrameInterval: iFrameInterval, rotation: rotation)
    }

    public func prepareVideo() -> Bool {
        prepareVideo(fps: 30, bitrate: 1200 * 1024, iFrameInterval: 2, rotation: 0)
    }

    public func setFpsListener(fpsCallback: FpsCallback) {
        fpsListener.setCallback(callback: fpsCallback)
    }

    private func startEncoders() {
        audioEncoder.start()
        videoEncoder.start()
        microphone.start()
        screenManager.start()
    }
    
    private func stopEncoders() {
        microphone.stop()
        screenManager.stop()
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

    public func isMuted() -> Bool {
        return microphone.isMuted()
    }
    
    public func mute() {
        microphone.mute()
    }
    
    public func unmute() {
        microphone.unmute()
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

    public func getPcmData(frame: PcmFrame) {
        recordController.recordAudio(pcmBuffer: frame.buffer, time: frame.time)
        audioEncoder.encodeFrame(frame: frame)
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
