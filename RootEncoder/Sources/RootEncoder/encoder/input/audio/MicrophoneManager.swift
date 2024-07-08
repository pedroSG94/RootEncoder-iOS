//
//  MicrophoneManager.swift
//  app
//
//  Created by Mac on 04/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation
import Accelerate

public class MicrophoneManager: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    private let thread = DispatchQueue(label: "MicrophoneManager")
    private var inputFormat: AVAudioFormat?
    var session: AVCaptureSession?
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var output: AVCaptureAudioDataOutput?
    private var muted = false
    private var running = false
    
    private var callback: GetMicrophoneData?
    
    public init(callback: GetMicrophoneData) {
        self.callback = callback
    }

    public func createMicrophone() -> Bool {
        session = AVCaptureSession()
        device = AVCaptureDevice.default(for: .audio)
        do {
            let input = try AVCaptureDeviceInput(device: device!)
            if session?.canAddInput(input) == true {
                session?.addInput(input)
            }
            self.input = input
            
            let output = AVCaptureAudioDataOutput()
            output.setSampleBufferDelegate(self, queue: thread)
            if session?.canAddOutput(output) == true {
                session?.addOutput(output)
            }
            self.output = output
            return true
        } catch {
            return false
        }
    }
    
    public func start() {
        running = true
        thread.async {
            self.session?.startRunning()
        }
    }
    
    public func stop() {
        session?.stopRunning()
        session?.removeOutput(output!)
        session?.removeInput(input!)
        running = false
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
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
            self.callback?.getPcmData(frame: PcmFrame(buffer: buffer.mute(enabled: muted), ts: ts, time: sampleBuffer.presentationTimeStamp))
        }
    }
}
