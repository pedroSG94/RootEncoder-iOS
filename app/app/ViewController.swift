//
//  ViewController.swift
//  app
//
//  Created by Pedro on 04/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, ConnectCheckerRtsp {
    
    
    @IBOutlet weak var tvEndpoint: UITextField!
    @IBOutlet weak var bStartStream: UIButton!
    @IBOutlet weak var cameraView: UIView!
    
    private var rtspCamera: RtspCamera!
    
    @IBAction func onClickStartStream(_ sender: UIButton) {
        let endpoint = tvEndpoint.text!
        if (!rtspCamera.isStreaming()) {
            if (rtspCamera.prepareAudio() && rtspCamera.prepareVideo()) {
                rtspCamera.startStream(endpoint: endpoint)
                bStartStream.setTitle("Stop stream", for: .normal)
            }
        } else {
            rtspCamera.stopStream()
            bStartStream.setTitle("Start stream", for: .normal)
        }
    }
    
    func onConnectionSuccessRtsp() {
        print("connection success")
    }
    
    func onConnectionFailedRtsp(reason: String) {
        print("connection failed: \(reason)")
        rtspCamera.stopStream()
    }
    
    func onNewBitrateRtsp(bitrate: UInt64) {
        print("new bitrate: \(bitrate)")
    }
    
    func onDisconnectRtsp() {
        print("disconnected")
    }
    
    func onAuthErrorRtsp() {
        print("auth error")
    }
    
    func onAuthSuccessRtsp() {
        print("auth success")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validatePermissions()
        rtspCamera = RtspCamera(view: cameraView, connectChecker: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) -> Void in
            self.rtspCamera.viewTransition()
        }, completion: { (context) -> Void in

        })
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        rtspCamera.stopStream()
    }
    
    func validatePermissions() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            print("microphone permission granted")
            break
        case .denied:
            print("microphone permission denied")
            break
        case .undetermined:
            break
        default:
            break
        }
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
                if response {
                    //access granted
                } else {

                }
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

