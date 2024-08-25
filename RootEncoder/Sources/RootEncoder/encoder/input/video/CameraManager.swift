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
    private var fpsLimiter = FpsLimiter()

    private var facing = CameraHelper.Facing.BACK
    private var width: Int = 640
    private var height: Int = 480
    private var resolution = CameraHelper.Resolution.vga640x480
    public var rotation: Int = 0
    private(set) var running = false
    private var callback: GetCameraData
    private var prepared = false
    
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

    public func prepare(width: Int, height: Int, fps: Int, rotation: Int, facing: CameraHelper.Facing = .BACK) -> Bool {
        let resolutions = facing == .BACK ? getBackCameraResolutions() : getFrontCameraResolutions()
        guard let lowerResolution = resolutions.first else { return false }
        guard let higherResolution = resolutions.last else { return false }
        if width < lowerResolution.width || height < lowerResolution.height { return false }
        if width > higherResolution.width || height > higherResolution.height { return false }
        do {
            let resolution = try CameraHelper.Resolution.getOptimalResolution(width: width, height: height)
            self.width = width
            self.height = height
            self.resolution = resolution
            fpsLimiter.setFps(fps: fps)
            self.rotation = rotation
            self.facing = facing
            prepared = true
            return true
        } catch {
            return false
        }
    }

    public func start() {
        start(width: width, height: height, facing: facing, rotation: rotation)
    }

    public func start(width: Int, height: Int) {
        start(width: width, height: width, facing: facing, rotation: rotation)
    }

    public func switchCamera() throws {
        if (facing == .FRONT) {
            facing = .BACK
        } else if (facing == .BACK) {
            facing = .FRONT
        }
        if (running) {
            stop()
            start(width: width, height: height, facing: facing, rotation: rotation)
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
        var resolutions = [CMVideoDimensions]()
        for size in sizes {
            var exists = false
            for r in resolutions {
                if r.width == size.width && r.height == size.height
                    //Currently the higher preset is 3840x2160
                    //More than 3840 width or 2160 height is not allowed because this need rescale producing bad image quality.
                    || size.height > 2160 || size.width > 3840 {
                    exists = true
                    break
                }
            }
            if !exists {
                resolutions.append(size)
            }
        }
        return resolutions.sorted(by: { $0.height < $1.height })
    }
    
    public func start(width: Int, height: Int, facing: CameraHelper.Facing, rotation: Int) {
        if !prepared {
            fatalError("CameraManager not prepared")
        }
        self.facing = facing
        if (running) {
            if (width != self.width || height != self.height || rotation != self.rotation) {
                stop()
            } else {
                return
            }
        }
        self.rotation = rotation
        session = AVCaptureSession()
        session?.sessionPreset = self.resolution.preset
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
