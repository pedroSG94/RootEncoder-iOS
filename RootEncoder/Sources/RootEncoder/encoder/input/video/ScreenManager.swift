//
//  ScreenManager.swift
//  encoder
//
//  Created by Pedro  on 23/10/23.
//

import Foundation
import ReplayKit

public class ScreenManager {
    
    private let screen = RPScreenRecorder.shared()
    private var running = false
    private let callbackVideo: GetCameraData?
    private var callbackAudio: GetMicrophoneData?
    private var muted = false
    private(set) var recordingInternalAudio = false
    
    public init(callbackVideo: GetCameraData?, callbackAudio: GetMicrophoneData?) {
        self.callbackVideo = callbackVideo
        self.callbackAudio = callbackAudio
        recordingInternalAudio = callbackAudio != nil
    }
    
    public func setAudioCallback(callbackAudio: GetMicrophoneData?) {
        self.callbackAudio = callbackAudio
        recordingInternalAudio = callbackAudio != nil
    }
    
    public func start() {
        if running {
            return
        }
        screen.isMicrophoneEnabled = false
        screen.startCapture(handler: { (sampleBuffer, bufferType, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            if (bufferType.rawValue == RPSampleBufferType.video.rawValue) {
                self.callbackVideo?.getYUVData(from: sampleBuffer)
            } else if (bufferType.rawValue == RPSampleBufferType.audioApp.rawValue) {
                let ts = UInt64(Date().millisecondsSince1970)
                
                guard let description = sampleBuffer.formatDescription, let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
                    return
                }
                let format = AVAudioFormat(cmAudioFormatDescription: description)
                
                var length = 0
                var dataPointer: UnsafeMutablePointer<Int8>?
                
                CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)
                
                let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(format.sampleRate))
                buffer?.frameLength = AVAudioFrameCount(length) / format.streamDescription.pointee.mBytesPerFrame
                memcpy(buffer?.int16ChannelData?[0], dataPointer, length)
                
                if let buffer = buffer {
                    self.callbackAudio?.getPcmData(frame: PcmFrame(buffer: buffer.mute(enabled: self.muted), ts: ts, time: sampleBuffer.presentationTimeStamp))
                }
            }
        }, completionHandler: { (error) in
            print(error?.localizedDescription ?? "")
        })
        running = true
    }
    
    public func stop() {
        if screen.isRecording {
            screen.stopCapture()
        }
        running = false
    }
    
    public func getWidth() -> Int {
        let screenRect = UIScreen.main.nativeBounds
        return Int(screenRect.width)
    }
    
    public func getHeight() -> Int {
        let screenRect = UIScreen.main.nativeBounds
        return Int(screenRect.height)
    }
    
    public func isMuted() -> Bool {
        return muted
    }
    
    public func mute() {
        muted = true
    }
    
    public func unmute() {
        muted = false
    }
}
