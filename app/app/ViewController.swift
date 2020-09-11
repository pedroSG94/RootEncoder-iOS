//
//  ViewController.swift
//  app
//
//  Created by Pedro on 04/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, GetMicrophoneData, ConnectCheckerRtsp {
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
    
    
    func getPcmData(frame: Frame) {
        print("new aac buffer")
        client?.sendAudio(buffer: frame.buffer!, ts: frame.timeStamp!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validatePermissions()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    private var client: RtspClient?
    
    func startMicrophone() {
        print("start microphone")
        client = RtspClient(connectCheckerRtsp: self)
        client?.setAudioInfo(sampleRate: 44100, isStereo: true)
        client?.connect(url: "rtsp://192.168.0.31:554/live/pedro")
        MicrophoneManager(callback: self).start()
    }
    
    func validatePermissions() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            self.startMicrophone()
            break
        case .denied:
            break
        case .undetermined:
            self.startMicrophone()
            break
        default:
            break
        }
    }
    
    func request() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                self.startMicrophone()
            } else {
                
            }
        }
    }
}

