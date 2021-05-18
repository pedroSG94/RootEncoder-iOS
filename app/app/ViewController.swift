//
//  ViewController.swift
//  app
//
//  Created by Pedro on 04/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, GetMicrophoneData, GetCameraData, GetAacData, GetH264Data,  ConnectCheckerRtsp {
    
    
    @IBOutlet weak var cameraview: UIView!
    
    func onConnectionSuccessRtsp() {
        print("success")
    }
    
    func onConnectionFailedRtsp(reason: String) {
        print("failed: \(reason)")
    }
    
    func onNewBitrateRtsp(bitrate: UInt64) {
        print("new bitrate")
    }
    
    func onDisconnectRtsp() {
        print("disconnect")
    }
    
    func onAuthErrorRtsp() {
        print("auth error")
    }
    
    func onAuthSuccessRtsp() {
        print("auth success")
    }
    
    func getAacData(frame: Frame) {
        client?.sendAudio(buffer: frame.buffer!, ts: frame.timeStamp!)
    }
    
    func getPcmData(from buffer: AVAudioPCMBuffer, initTS: Int64) {
        audioEncoder?.encodeFrame(from: buffer, initTS: initTS)
    }
    
    func getH264Data(frame: Frame) {
        client?.sendVideo(buffer: frame.buffer!, ts: frame.timeStamp!)
    }
    
    func getYUVData(from buffer: CMSampleBuffer) {
        videoEncoder?.encodeFrame(buffer: buffer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validatePermissions()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraManager = CameraManager(cameraView: cameraview, callback: self)
        cameraManager?.createSession()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) -> Void in
            self.cameraManager?.viewTransation()
        }, completion: { (context) -> Void in

        })
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
//        microphone?.stop()
//        client?.disconnect()
    }
    
    private var client: RtspClient?
    private var microphone: MicrophoneManager?
    private var cameraManager: CameraManager?
    private var audioEncoder: AudioEncoder?
    private var videoEncoder: VideoEncoder?
    
    func startStream() {
        print("start microphone")
        client = RtspClient(connectCheckerRtsp: self)

        videoEncoder = VideoEncoder(callback: self)
        microphone?.start()
    }
    
    func validatePermissions() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            self.startStream()
            break
        case .denied:
            break
        case .undetermined:
            self.startStream()
            break
        default:
            break
        }
    }
    
    func request() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                self.startStream()
            } else {
                
            }
        }
    }
}

