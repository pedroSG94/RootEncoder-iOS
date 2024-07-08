//
//  RtmpSwiftUIView.swift
//  app
//
//  Created by Pedro  on 20/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import SwiftUI
import RootEncoder
import Photos

struct RtmpSwiftUIView: View, ConnectChecker {
    
    func onConnectionSuccess() {
        print("connection success")
        toastText = "connection success"
        isShowingToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isShowingToast = false
        }
    }
    
    func onConnectionFailed(reason: String) {
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
    
    func onNewBitrate(bitrate: UInt64) {
        print("new bitrate: \(bitrate)")
        bitrateText = "bitrate: \(bitrate) bps"
    }
    
    func onDisconnect() {
        print("disconnected")
        toastText = "disconnected"
        isShowingToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isShowingToast = false
        }
    }
    
    func onAuthError() {
        print("auth error")
        toastText = "auth error"
        isShowingToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isShowingToast = false
        }
    }
    
    func onAuthSuccess() {
        print("auth success")
        toastText = "auth success"
        isShowingToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isShowingToast = false
        }
    }
    
    
    @State private var endpoint = "rtmp://192.168.0.176:1925/live/pedro"
    @State private var bStreamText = "Start stream"
    @State private var bRecordText = "Start record"
    @State private var isShowingToast = false
    @State private var toastText = ""
    @State private var bitrateText = ""
    @State private var filePath: URL? = nil
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
                HStack {
                    Spacer()
                    Menu("Filters") {
                        Button(action: {
                            rtmpCamera.metalInterface?.clearFilters()
                        }) {
                            Text("No filter")
                        }
                        Button(action: {
                            rtmpCamera.metalInterface?.setFilter(baseFilterRender: GreyScaleFilterRender())
                        }) {
                            Text("GreyScale")
                        }
                        Button(action: {
                            rtmpCamera.metalInterface?.setFilter(baseFilterRender: SepiaFilterRender())
                        }) {
                            Text("Sepia")
                        }
                    }
                }.padding(.trailing, 16)
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
                    Button(bRecordText) {
                        if (!rtmpCamera.isRecording()) {
                            if (rtmpCamera.prepareAudio() && rtmpCamera.prepareVideo()) {
                                let url = getVideoUrl()
                                if (url != nil) {
                                    filePath = url
                                    rtmpCamera.startRecord(path: url!)
                                    bRecordText = "Stop record"
                                }
                            }
                        } else {
                            rtmpCamera.stopRecord()
                            if (filePath != nil) {
                                saveVideoToGallery(videoURL: filePath!)
                                filePath = nil
                            }
                            bRecordText = "Start record"
                        }
                    }.font(.system(size: 20, weight: Font.Weight.bold))
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
                    }.font(.system(size: 20, weight: Font.Weight.bold))
                    Button("Switch camera") {
                        if rtmpCamera.isMuted() {
                            rtmpCamera.unmute()
                        } else {
                            rtmpCamera.mute()
                        }
                    }.font(.system(size: 20, weight: Font.Weight.bold))
                }).padding(.bottom, 24)
            }.frame(alignment: .bottom)
        }.showToast(text: toastText, isShowing: $isShowingToast)
    }
}

#Preview {
    RtmpSwiftUIView()
}

