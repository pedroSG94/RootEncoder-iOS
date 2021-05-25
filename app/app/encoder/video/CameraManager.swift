//
//  CameraManager.swift
//  app
//
//  Created by Pedro on 13/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

public class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var session: AVCaptureSession?
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var output: AVCaptureVideoDataOutput?
    var prevLayer: AVCaptureVideoPreviewLayer?
    var videoOutput: AVCaptureVideoDataOutput?
    var cameraView: UIView!
    
    private var width = 640
    private var height = 480
    private var attributes: [NSString: NSObject] {
            var attributes: [NSString: NSObject] = [
                kCVPixelBufferPixelFormatTypeKey: NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),
                kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue,
                kCVPixelBufferOpenGLESCompatibilityKey: kCFBooleanTrue
            ]
            attributes[kCVPixelBufferWidthKey] = NSNumber(value: width)
            attributes[kCVPixelBufferHeightKey] = NSNumber(value: height)
            return attributes
        }
    
    private var _pixelBufferPool: CVPixelBufferPool?
        private var pixelBufferPool: CVPixelBufferPool! {
            get {
                if _pixelBufferPool == nil {
                    var pixelBufferPool: CVPixelBufferPool?
                    CVPixelBufferPoolCreate(nil, nil, attributes as CFDictionary?, &pixelBufferPool)
                    _pixelBufferPool = pixelBufferPool
                }
                return _pixelBufferPool!
            }
            set {
                _pixelBufferPool = newValue
            }
        }
    
    private var callback: GetCameraData
    
    public init(cameraView: UIView, callback: GetCameraData) {
        self.cameraView = cameraView
        self.callback = callback
    }
    
    public func stop() {
        session?.stopRunning()
        session?.removeOutput(output!)
        session?.removeInput(input!)
    }
    
    public func createSession() {
        prevLayer?.frame.size = cameraView.frame.size
        session = AVCaptureSession()
        let preset: AVCaptureSession.Preset = .vga640x480
        session?.sessionPreset = preset
        device = AVCaptureDevice.default(for: AVMediaType.video)

        do{
            input = try AVCaptureDeviceInput(device: device!)
        }
        catch{
            print(error)
        }

        if let input = input{
            session?.addInput(input)
        }

        session?.commitConfiguration()
        prevLayer = AVCaptureVideoPreviewLayer(session: session!)
        prevLayer?.frame.size = cameraView.frame.size
        prevLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        prevLayer?.connection?.videoOrientation = transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
        cameraView.layer.addSublayer(prevLayer!)
        
        output = AVCaptureVideoDataOutput()

        let thread = DispatchQueue.global()
        output?.setSampleBufferDelegate(self, queue: thread)
        output?.alwaysDiscardsLateVideoFrames = true
        output?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        
        session?.addOutput(output!)
        session?.startRunning()
    }
    
    public func viewTransation() {
        self.prevLayer?.connection?.videoOrientation = self.transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
        self.prevLayer?.frame.size = self.cameraView.frame.size
    }
    
    public func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInTelephotoCamera, .builtInTrueDepthCamera, .builtInWideAngleCamera, ], mediaType: .video, position: position)

        if let device = deviceDiscoverySession.devices.first {
            return device
        }
        return nil
    }
    
    private func transformOrientation(orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        callback.getYUVData(from: sampleBuffer)
    }
}
