//
//  ViewController.swift
//  app
//
//  Created by Mac on 04/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, GetMicrophoneData {
    func getPcmData(frame: Frame) {
        print("new pcm buffer")
    }
    

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validatePermissions()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    func startMicrophone() {
        print("start microphone")
        MicrophoneManager(callback: self).start()
    }
    
    func validatePermissions() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
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

