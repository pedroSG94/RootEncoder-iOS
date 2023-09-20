//
//  RtmpSwiftUIView.swift
//  app
//
//  Created by Pedro  on 20/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import SwiftUI

struct RtmpSwiftUIView: View, ConnectCheckerRtmp {
    
    func onConnectionSuccessRtmp() {
        print("connection success")
    }
    
    func onConnectionFailedRtmp(reason: String) {
        print("connection failed: \(reason)")
        rtmpCamera.stopStream()
    }
    
    func onNewBitrateRtmp(bitrate: UInt64) {
        print("new bitrate: \(bitrate)")
    }
    
    func onDisconnectRtmp() {
        print("disconnected")
    }
    
    func onAuthErrorRtmp() {
        print("auth error")
    }
    
    func onAuthSuccessRtmp() {
        print("auth success")
    }
    
    
    @State private var endpoint = "rtmp://192.168.0.177:1935/live/pedro"
    @State private var bStreamText = "Start stream"
    @State private var rtmpCamera: CameraBase!
    
    var body: some View {
        ZStack {
            let camera = CameraUIView()
            let cameraView = camera.view
            camera.edgesIgnoringSafeArea(.all)
            
            camera.onAppear {
                rtmpCamera = RtmpCamera(view: cameraView, connectChecker: self)
                rtmpCamera.startPreview()
            }
            camera.onDisappear {
                if (rtmpCamera.isStreaming()) {
                    rtmpCamera.stopStream()
                }
                if (rtmpCamera.isOnPreview()) {
                    rtmpCamera.stopPreview()
                }
            }
            
            VStack {
                TextField("rtmp://ip:port/app/streamname", text: $endpoint)
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
                        if (!rtmpCamera.isStreaming()) {
                            if (rtmpCamera.prepareAudio() && rtmpCamera.prepareVideo()) {
                                rtmpCamera.startStream(endpoint: endpoint)
                                bStreamText = "Stop stream"
                            }
                        } else {
                            rtmpCamera.stopStream()
                            bStreamText = "Start stream"
                        }
                    }
                    Button("Switch camera") {
                        rtmpCamera.switchCamera()
                    }
                }).padding(.bottom, 24)
            }.frame(width: .infinity, height: .infinity, alignment: .bottom)
        }
    }
}

#Preview {
    RtmpSwiftUIView()
}
