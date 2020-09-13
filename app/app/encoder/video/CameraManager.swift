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
    var output: AVCaptureMetadataOutput?
    var prevLayer: AVCaptureVideoPreviewLayer?
    var videoOutput: AVCaptureVideoDataOutput?
    var cameraView: UIView!
    
    public init(cameraView: UIView) {
        self.cameraView = cameraView
    }
    
    public func createSession() {
        prevLayer?.frame.size = cameraView.frame.size
        session = AVCaptureSession()
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

        prevLayer = AVCaptureVideoPreviewLayer(session: session!)
        prevLayer?.frame.size = cameraView.frame.size
        prevLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill

        prevLayer?.connection?.videoOrientation = transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
        cameraView.layer.addSublayer(prevLayer!)

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
        print("raw camera frame")
    }
}
