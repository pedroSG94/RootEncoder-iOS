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
    
    private let thread = DispatchQueue.global()
    var session: AVCaptureSession?
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var output: AVCaptureVideoDataOutput?
    var prevLayer: AVCaptureVideoPreviewLayer?
    var videoOutput: AVCaptureVideoDataOutput?
    var cameraView: UIView!

    private var facing = CameraHelper.Facing.BACK
    private var resolution: CameraHelper.Resolution = .vga640x480
    private(set) var running = false
    private(set) var onPreview = false
    private var callback: GetCameraData
    
    public init(cameraView: UIView, callback: GetCameraData) {
        self.cameraView = cameraView
        self.callback = callback
    }

    public func stopSend() {
        onPreview = true
    }

    public func stop() {
        session?.stopRunning()
        session?.removeOutput(output!)
        session?.removeInput(input!)
        running = false
        onPreview = false
    }

    public func prepare(resolution: CameraHelper.Resolution) {
        self.resolution = resolution
    }

    public func start(onPreview: Bool = false) {
        start(facing: facing, resolution: resolution, onPreview: onPreview)
    }

    public func start(onPreview: Bool = false, resolution: CameraHelper.Resolution) {
        start(facing: facing, resolution: resolution, onPreview: onPreview)
    }

    public func switchCamera() {
        if (facing == .FRONT) {
            facing = .BACK
        } else if (facing == .BACK) {
            facing = .FRONT
        }
        if (running) {
            stop()
            start(facing: facing, resolution: resolution, onPreview: onPreview)
        }
    }
    
    public func start(facing: CameraHelper.Facing, resolution: CameraHelper.Resolution, onPreview: Bool) {
        self.onPreview = onPreview
        if (running && resolution.value != self.resolution.value) {
            stop()
        }
        session = AVCaptureSession()
        let preset: AVCaptureSession.Preset = resolution.value
        session?.sessionPreset = preset
        let position = facing == CameraHelper.Facing.BACK ? AVCaptureDevice.Position.back : AVCaptureDevice.Position.front
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: position)
        device = devices.devices[0]

        do{
            input = try AVCaptureDeviceInput(device: device!)
        }
        catch{
            print(error)
        }

        if let input = input{
            session?.addInput(input)
        }

        output = AVCaptureVideoDataOutput()
        let thread = DispatchQueue.global()
        output?.setSampleBufferDelegate(self, queue: thread)
        output?.alwaysDiscardsLateVideoFrames = true
        output?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]

        session?.addOutput(output!)

        prevLayer = AVCaptureVideoPreviewLayer(session: session!)
        prevLayer?.frame.size = cameraView.frame.size
        prevLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        prevLayer?.connection?.videoOrientation = transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
        cameraView.layer.addSublayer(prevLayer!)

        session?.commitConfiguration()
        session?.startRunning()
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
        thread.async {
            //TODO render OpenGlView/MetalView using CMSampleBuffer to draw preview and filters
            if (!self.onPreview) {
                self.callback.getYUVData(from: sampleBuffer)
            }
        }
    }
}
