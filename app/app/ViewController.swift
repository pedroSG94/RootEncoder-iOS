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
    
    override func viewDidDisappear(_ animated: Bool) {
        microphone?.stop()
        client?.disconnect()
    }
    
    private var client: RtspClient?
    private var microphone: MicrophoneManager?
    
    public func setLong(buffer: inout Array<UInt8>, n: inout Int64, begin: Int, end: Int) {
        let start = end - 1
        for i in stride(from: start, to: begin - 1, by: -1) {
            print("n: \(n)")
            let a = intToBytes(from: n % 256)
            print("a: \(a)")
            buffer[i] = a[0]
            print("n %: \(n % 256)")
            n >>= 8
        }
    }
    
    func startMicrophone() {
        print("start microphone")
        client = RtspClient(connectCheckerRtsp: self)
        client?.setOnlyAudio(onlyAudio: true)
        client?.setAudioInfo(sampleRate: 44100, isStereo: true)
        client?.connect(url: "rtsp://192.168.0.31:554/live/pedro")
        microphone = MicrophoneManager(callback: self)
        microphone?.start()
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

