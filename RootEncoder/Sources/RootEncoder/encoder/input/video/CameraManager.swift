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
    private var preset: AVCaptureSession.Preset = .high
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
        prevLayer?.removeFromSuperlayer()
        prevLayer = nil
        session?.stopRunning()
        session?.removeOutput(output!)
        session?.removeInput(input!)
        running = false
    }

    public func prepare(preset: AVCaptureSession.Preset, fps: Int, rotation: Int) {
        self.preset = preset
        fpsLimiter.setFps(fps: fps)
        self.rotation = rotation
    }

    public func start() {
        start(preset: preset, facing: facing, rotation: rotation)
    }

    public func start(preset: AVCaptureSession.Preset) {
        start(preset: preset, facing: facing, rotation: rotation)
    }

    public func switchCamera() {
        if (facing == .FRONT) {
            facing = .BACK
        } else if (facing == .BACK) {
            facing = .FRONT
        }
        if (running) {
            stop()
            start(preset: preset, facing: facing, rotation: rotation)
        }
    }
    
    @discardableResult
    public func setTorch(isOn: Bool) -> Bool {
        guard let device, device.hasTorch else {
            return false
        }
        do {
            let torchMode: AVCaptureDevice.TorchMode = isOn ? .on : .off
            try device.lockForConfiguration()
            if device.isTorchModeSupported(torchMode) {
                device.torchMode = torchMode
            }
            device.unlockForConfiguration()
            return true
        } catch {
            return false
        }
    }
    
    public func isTorchEnabled() -> Bool {
        guard let device, device.hasTorch else {
            return false
        }
        return device.isTorchActive
    }
    
    public func getBackCameraResolutions() -> [CMVideoDimensions] {
        return getResolutionsByFace(facing: .BACK)
    }
    
    public func getFrontCameraResolutions() -> [CMVideoDimensions] {
        return getResolutionsByFace(facing: .FRONT)
    }
    
    public func getResolutionsByFace(facing: CameraHelper.Facing) -> [CMVideoDimensions] {
        let position = facing == CameraHelper.Facing.BACK ? AVCaptureDevice.Position.back : AVCaptureDevice.Position.front
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: position)
        let device = devices.devices[0]
        let descriptions = device.formats.map(\.formatDescription)
        let sizes = descriptions.map(\.dimensions)
        return sizes
    }
    
    public func start(preset: AVCaptureSession.Preset, facing: CameraHelper.Facing, rotation: Int) {
        self.facing = facing
        if (running) {
            if (preset != self.preset || rotation != self.rotation) {
                stop()
            } else {
                return
            }
        }
        self.rotation = rotation
        self.preset = preset
        session = AVCaptureSession()
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
    
    public func getCaptureSession() -> AVCaptureSession? {
        session
    }
}
