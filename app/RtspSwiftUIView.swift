//
//  RtspSwiftUIView.swift
//  app
//
//  Created by Pedro  on 20/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import SwiftUI

struct RtspSwiftUIView: View, ConnectCheckerRtsp {
    
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
    
    
    @State private var endpoint = "rtsp://192.168.0.177:8554/live/pedro"
    @State private var bStreamText = "Start stream"
    @State private var rtspCamera: CameraBase!
    
    var body: some View {
        ZStack {
            let camera = CameraUIView()
            let cameraView = camera.view
            camera.edgesIgnoringSafeArea(.all)
            
            camera.onAppear {
                rtspCamera = RtspCamera(view: cameraView, connectChecker: self)
                rtspCamera.startPreview()
            }
            camera.onDisappear {
                if (rtspCamera.isStreaming()) {
                    rtspCamera.stopStream()
                }
                if (rtspCamera.isOnPreview()) {
                    rtspCamera.stopPreview()
                }
            }
            
            VStack {
                TextField("rtsp://ip:port/app/streamname", text: $endpoint)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .padding(.top, 24)
                    .padding(.horizontal)
                    .keyboardType(.default)
                
                Spacer()
                HStack(alignment: .center, spacing: 16, content: {
                    Button(bStreamText) {
                        let endpoint = endpoint
                        if (!rtspCamera.isStreaming()) {
                            if (rtspCamera.prepareAudio() && rtspCamera.prepareVideo()) {
                                rtspCamera.startStream(endpoint: endpoint)
                                bStreamText = "Stop stream"
                            }
                        } else {
                            rtspCamera.stopStream()
                            bStreamText = "Start stream"
                        }
                    }
                    Button("Switch camera") {
                        rtspCamera.switchCamera()
                    }
                }).padding(.bottom, 24)
            }.frame(width: .infinity, height: .infinity, alignment: .bottom)
        }
    }
}

#Preview {
    RtspSwiftUIView()
}
