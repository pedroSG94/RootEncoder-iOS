//
//  DisplayBase.swift
//  RootEncoder
//
//  Created by Pedro  on 24/10/23.
//

import Foundation
import AVFoundation
import UIKit

public class DisplayBase {

    private var microphone: MicrophoneManager!
    private var screenManager: ScreenManager!
    private var audioEncoder: AudioEncoder!
    internal var videoEncoder: VideoEncoder!
    private(set) var endpoint: String = ""
    private var streaming = false
    private var onPreview = false
    private var fpsListener = FpsListener()
    private let recordController = RecordController()
    private var callback: DisplayBaseCallback? = nil
    private(set) public var metalInterface: MetalInterface

    public init() {
        self.metalInterface = MetalStreamInterface()
        let callback = createDisplayBaseCallbacks()
        self.callback = callback
        screenManager = ScreenManager(callbackVideo: callback, callbackAudio: nil)
        microphone = MicrophoneManager(callback: callback)
        videoEncoder = VideoEncoder(callback: callback)
        audioEncoder = AudioEncoder(callback: callback)
    }

    func onAudioInfoImp(sampleRate: Int, isStereo: Bool) {}

    public func prepareInternalAudio(bitrate: Int, sampleRate: Int, isStereo: Bool) -> Bool {
        let channels = isStereo ? 2 : 1
        recordController.setAudioFormat(sampleRate: sampleRate, channels: channels, bitrate: bitrate)
        screenManager.setAudioCallback(callbackAudio: callback)
        onAudioInfoImp(sampleRate: sampleRate, isStereo: isStereo)
        return audioEncoder.prepareAudio(sampleRate: Double(sampleRate), channels: UInt32(channels), bitrate: bitrate)
    }
    
    public func prepareInternalAudio() -> Bool {
        prepareInternalAudio(bitrate: 128 * 1024, sampleRate: 32000, isStereo: true)
    }

    public func prepareAudio(bitrate: Int, sampleRate: Int, isStereo: Bool) -> Bool {
        let channels = isStereo ? 2 : 1
        recordController.setAudioFormat(sampleRate: sampleRate, channels: channels, bitrate: bitrate)
        screenManager.setAudioCallback(callbackAudio: nil)
        let createResult = microphone.createMicrophone()
        if !createResult {
            return false
        }
        onAudioInfoImp(sampleRate: sampleRate, isStereo: isStereo)
        return audioEncoder.prepareAudio(sampleRate: Double(sampleRate), channels: UInt32(channels), bitrate: bitrate)
    }

    public func prepareAudio() -> Bool {
        prepareAudio(bitrate: 128 * 1024, sampleRate: 32000, isStereo: true)
    }

    public func prepareVideo(width: Int, height: Int, fps: Int, bitrate: Int, iFrameInterval: Int, rotation: Int = 0) -> Bool {
        metalInterface.setEncoderSize(width: width, height: height)
        metalInterface.setForceFps(fps: fps)
        metalInterface.setOrientation(orientation: rotation)
        recordController.setVideoFormat(witdh: width, height: height, bitrate: bitrate)
        return videoEncoder.prepareVideo(width: width, height: height, fps: fps, bitrate: bitrate, iFrameInterval: iFrameInterval, rotation: rotation)
    }

    public func prepareVideo() -> Bool {
        let w = screenManager.getWidth()
        let h = screenManager.getHeight()
        return prepareVideo(width: w, height: h, fps: 30, bitrate: 1200 * 1024, iFrameInterval: 2, rotation: 0)
    }

    public func setFpsListener(fpsCallback: FpsCallback) {
        fpsListener.setCallback(callback: fpsCallback)
    }

    private func startEncoders() {
        audioEncoder.start()
        videoEncoder.start()
        microphone.start()
        screenManager.start()
        metalInterface.setCallback(callback: callback)
    }
    
    private func stopEncoders() {
        metalInterface.setCallback(callback: nil)
        microphone.stop()
        screenManager.stop()
        audioEncoder.stop()
        videoEncoder.stop()
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
        if screenManager.recordingInternalAudio {
            return screenManager.isMuted()
        } else {
            return microphone.isMuted()
        }
    }
    
    public func mute() {
        microphone.mute()
        screenManager.mute()
    }
    
    public func unmute() {
        microphone.unmute()
        screenManager.unmute()
    }
    
    public func setVideoBitrateOnFly(bitrate: Int) {
        videoEncoder.setVideoBitrateOnFly(bitrate: bitrate)
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

    public func getPcmData(frame: PcmFrame) {
        recordController.recordAudio(pcmBuffer: frame.buffer, time: frame.time)
        audioEncoder.encodeFrame(frame: frame)
    }

    public func getYUVData(from buffer: CMSampleBuffer) {
        recordController.recordVideo(buffer: buffer)
        videoEncoder.encodeFrame(buffer: buffer)
    }

    public func getAudioData(frame: Frame) {
        getAudioDataImp(frame: frame)
    }

    public func getVideoData(frame: Frame) {
        fpsListener.calculateFps()
        getVideoDataImp(frame: frame)
    }

    public func onVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        onVideoInfoImp(sps: sps, pps: pps, vps: vps)
    }
}

protocol DisplayBaseCallback: GetMicrophoneData, GetCameraData, GetAudioData, GetVideoData, MetalViewCallback {}

extension DisplayBase {
    func createDisplayBaseCallbacks() -> DisplayBaseCallback {
        class DisplayBaseCallbackHandler: DisplayBaseCallback {
            
            private let displayBase: DisplayBase
            
            init(displayBase: DisplayBase) {
                self.displayBase = displayBase
            }
            
            public func getPcmData(frame: PcmFrame) {
                displayBase.recordController.recordAudio(pcmBuffer: frame.buffer, time: frame.time)
                displayBase.audioEncoder.encodeFrame(frame: frame)
            }

            public func getYUVData(from buffer: CMSampleBuffer) {
                displayBase.metalInterface.sendBuffer(buffer: buffer)
            }
            
            func getVideoData(pixelBuffer: CVPixelBuffer, pts: CMTime) {
                displayBase.recordController.recordVideo(pixelBuffer: pixelBuffer, pts: pts)
                displayBase.videoEncoder.encodeFrame(pixelBuffer: pixelBuffer, pts: pts)
            }

            public func getAudioData(frame: Frame) {
                displayBase.getAudioDataImp(frame: frame)
            }

            public func getVideoData(frame: Frame) {
                displayBase.fpsListener.calculateFps()
                displayBase.getVideoDataImp(frame: frame)
            }

            public func onVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
                displayBase.onVideoInfoImp(sps: sps, pps: pps, vps: vps)
            }
        }
        return DisplayBaseCallbackHandler(displayBase: self)
    }
}
