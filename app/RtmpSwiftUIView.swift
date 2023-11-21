//
//  RtmpSwiftUIView.swift
//  app
//
//  Created by Pedro  on 20/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import SwiftUI
import RootEncoder
import rtmp

struct RtmpSwiftUIView: View, ConnectCheckerRtmp {
    
    func onConnectionSuccessRtmp() {
        print("connection success")
        toastText = "connection success"
        isShowingToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isShowingToast = false
        }
    }
    
    func onConnectionFailedRtmp(reason: String) {
        print("connection failed: \(reason)")
        if (rtmpCamera.reTry(delay: 5000, reason: reason)) {
            toastText = "Retry"
            isShowingToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isShowingToast = false
            }
        } else {
            rtmpCamera.stopStream()
            bStreamText = "Start stream"
            bitrateText = ""
            toastText = "connection failed: \(reason)"
            isShowingToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isShowingToast = false
            }
        }
    }
    
    func onNewBitrateRtmp(bitrate: UInt64) {
        print("new bitrate: \(bitrate)")
        bitrateText = "bitrate: \(bitrate) bps"
    }
    
    func onDisconnectRtmp() {
        print("disconnected")
        toastText = "disconnected"
        isShowingToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isShowingToast = false
        }
    }
    
    func onAuthErrorRtmp() {
        print("auth error")
        toastText = "auth error"
        isShowingToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isShowingToast = false
        }
    }
    
    func onAuthSuccessRtmp() {
        print("auth success")
        toastText = "auth success"
        isShowingToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isShowingToast = false
        }
    }
    
    
    @State private var endpoint = "rtmp://192.168.0.160:1935/live/pedro"
    @State private var bStreamText = "Start stream"
    @State private var isShowingToast = false
    @State private var toastText = ""
    @State private var bitrateText = ""

    @State private var rtmpCamera: RtmpCamera!
    
    var body: some View {
        ZStack {
            let camera = CameraUIView()
            let cameraView = camera.view
            camera.edgesIgnoringSafeArea(.all)
            
            camera.onAppear {
                rtmpCamera = RtmpCamera(view: cameraView, connectChecker: self)
                rtmpCamera.setRetries(reTries: 10)
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
                Text(bitrateText).foregroundColor(Color.blue)
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
                            bitrateText = ""
                        }
                    }
                    Button("Switch camera") {
                        rtmpCamera.switchCamera()
                    }
                }).padding(.bottom, 24)
            }.frame(alignment: .bottom)
        }.showToast(text: toastText, isShowing: $isShowingToast)
    }
}

#Preview {
    RtmpSwiftUIView()
}
