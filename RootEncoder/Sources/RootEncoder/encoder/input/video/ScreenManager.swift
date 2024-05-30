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
    private let callbackAudio: GetMicrophoneData?
    
    public init(callbackVideo: GetCameraData?, callbackAudio: GetMicrophoneData?) {
        self.callbackVideo = callbackVideo
        self.callbackAudio = callbackAudio
    }
    
    public func start() {
        if running {
            return
        }
        screen.isMicrophoneEnabled = false
        screen.startCapture(handler: { (buffer, bufferType, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            print("type: \(bufferType.rawValue)")
            if (bufferType.rawValue == RPSampleBufferType.video.rawValue) {
                let w = buffer.formatDescription?.dimensions.width
                let h = buffer.formatDescription?.dimensions.height
                print("\(w)x\(h), \(self.getWidth())x\(self.getHeight())")
                self.callbackVideo?.getYUVData(from: buffer)
            } else if (bufferType.rawValue == RPSampleBufferType.audioApp.rawValue) {
                //self.callbackAudio?.getPcmData(buffer: buffer)
            }
        }, completionHandler: { (error) in
            print(error?.localizedDescription ?? "")
        })
        running = true
    }
    
    public func stop() {
        screen.stopCapture()
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
}
