//
//  ViewController.swift
//  app
//
//  Created by Pedro on 04/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, GetMicrophoneData, GetAacData, ConnectCheckerRtsp {
    
    
    
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
    private var audioEncoder: AudioEncoder?
    
    func startMicrophone() {
        print("start microphone")
        client = RtspClient(connectCheckerRtsp: self)
        client?.setOnlyAudio(onlyAudio: true)
        client?.setAudioInfo(sampleRate: 44100, isStereo: false)
        client?.connect(url: "rtsp://192.168.0.31:554/live/pedro")
        microphone = MicrophoneManager(callback: self)
        audioEncoder = AudioEncoder(inputFormat: microphone!.getInputFormat(), callback: self)
        audioEncoder?.prepareAudio(sampleRate: 44100, channels: 1, bitrate: 32000)
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

