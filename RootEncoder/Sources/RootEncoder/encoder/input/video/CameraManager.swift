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
    
    private let thread = DispatchQueue(label: "CameraManager")
    var session: AVCaptureSession?
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var output: AVCaptureVideoDataOutput?
    var prevLayer: AVCaptureVideoPreviewLayer?
    var videoOutput: AVCaptureVideoDataOutput?
    var cameraView: UIView? = nil
    private var fpsLimiter = FpsLimiter()

    private var facing = CameraHelper.Facing.BACK
    //TODO fix use different resolution in startPreview and in prepareVideo
    private var resolution: CameraHelper.Resolution = .vga640x480
    public var rotation: Int = 0
    private(set) var running = false
    private var callback: GetCameraData
    
    public init(cameraView: UIView, callback: GetCameraData) {
        self.cameraView = cameraView
        self.callback = callback
    }
    
    public init(callback: GetCameraData) {
        self.callback = callback
    }

    public func stop() {
        session?.stopRunning()
        session?.removeOutput(output!)
        session?.removeInput(input!)
        running = false
    }

    public func prepare(resolution: CameraHelper.Resolution, fps: Int, rotation: Int) {
        self.resolution = resolution
        fpsLimiter.setFps(fps: fps)
        self.rotation = rotation
    }

    public func start() {
        start(facing: facing, resolution: resolution, rotation: rotation)
    }

    public func start(resolution: CameraHelper.Resolution) {
        start(facing: facing, resolution: resolution, rotation: rotation)
    }

    public func switchCamera() {
        if (facing == .FRONT) {
            facing = .BACK
        } else if (facing == .BACK) {
            facing = .FRONT
        }
        if (running) {
            stop()
            start(facing: facing, resolution: resolution, rotation: rotation)
        }
    }
    
    public func start(facing: CameraHelper.Facing, resolution: CameraHelper.Resolution, rotation: Int) {
        self.facing = facing
        if (running) {
            if (resolution != self.resolution || rotation != self.rotation) {
                stop()
            } else {
                return
            }
        }
        self.rotation = rotation
        self.resolution = resolution
        session = AVCaptureSession()
        let preset: AVCaptureSession.Preset = resolution.value
        session?.sessionPreset = preset
        let position = facing == CameraHelper.Facing.BACK ? AVCaptureDevice.Position.back : AVCaptureDevice.Position.front
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: position)
        device = devices.devices[0]

        do{
            input = try AVCaptureDeviceInput(device: device!)
        } catch {
            print(error)
        }

        if let input = input{
            session?.addInput(input)
        }

        output = AVCaptureVideoDataOutput()
        output?.setSampleBufferDelegate(self, queue: thread)
        output?.alwaysDiscardsLateVideoFrames = true
        output?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)]

        session?.addOutput(output!)

        prevLayer = AVCaptureVideoPreviewLayer(session: session!)
        if (cameraView != nil) {
            prevLayer?.frame.size = cameraView!.frame.size
        }
        prevLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        if let interfaceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation {
            let orientation = UIInterfaceOrientation(rawValue: interfaceOrientation.rawValue)!
            prevLayer?.connection?.videoOrientation = transformOrientation(orientation: orientation)
        }
        if (cameraView != nil) {
            cameraView!.layer.addSublayer(prevLayer!)
        }
        output?.connections.filter { $0.isVideoOrientationSupported }.forEach {
            $0.videoOrientation = getOrientation(value: rotation)
        }
        session?.commitConfiguration()
        thread.async {
            self.session?.startRunning()
        }
        running = true
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
        if !fpsLimiter.limitFps() {
            self.callback.getYUVData(from: sampleBuffer)
        }
    }
    
    private func getOrientation(value: Int) -> AVCaptureVideoOrientation {
        switch value {
        case 90:
            return .portrait
        case 270:
            return .portraitUpsideDown
        case 0:
            return .landscapeLeft
        case 180:
            return .landscapeRight
        default:
            return .landscapeLeft
        }
    }
    
    @discardableResult
    public func configureCaptureSession(with configuration: (AVCaptureSession) -> Bool) -> Bool {
        if let session {
            return configuration(session)
        }
        return false
    }
    
}
