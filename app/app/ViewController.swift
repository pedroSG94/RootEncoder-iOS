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
    
    
    @IBOutlet weak var tvEndpoint: UITextField!
    @IBOutlet weak var bStartStream: UIButton!
    @IBOutlet weak var cameraview: UIView!
    
    private var client: RtspClient?
    private var microphone: MicrophoneManager?
    private var cameraManager: CameraManager?
    private var audioEncoder: AudioEncoder?
    private var videoEncoder: VideoEncoder?
    private var endpoint: String? = nil
    
    @IBAction func onClickstartStream(_ sender: UIButton) {
        endpoint = tvEndpoint.text!
        client = RtspClient(connectCheckerRtsp: self)
        cameraManager = CameraManager(cameraView: cameraview, callback: self)
        microphone = MicrophoneManager(callback: self)
        videoEncoder = VideoEncoder(callback: self)
        audioEncoder = AudioEncoder(inputFormat: microphone!.getInputFormat(), callback: self)
        
        client?.setAudioInfo(sampleRate: 44100, isStereo: true)
        audioEncoder?.prepareAudio(sampleRate: 44100, channels: 2, bitrate: 64 * 1000)
        videoEncoder?.prepareVideo()
        cameraManager?.createSession()
    }
    
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
    
    func getSpsAndPps(sps: Array<UInt8>, pps: Array<UInt8>) {
        print("connecting...")
        client?.setVideoInfo(sps: sps, pps: pps, vps: nil)
        client?.connect(url: endpoint!)
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
    
    
    
    func validatePermissions() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            break
        case .denied:
            break
        case .undetermined:
            break
        default:
            break
        }
    }
    
    func request() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
               
            } else {
                
            }
        }
    }
}

