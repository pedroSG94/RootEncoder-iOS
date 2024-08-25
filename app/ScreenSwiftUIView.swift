//
//  ScreenSwiftUIView.swift
//  app
//
//  Created by Pedro  on 30/5/24.
//  Copyright © 2024 pedroSG94. All rights reserved.
//

import Foundation

import SwiftUI
import RootEncoder

struct ScreenSwiftUIView: View, ConnectChecker {
    
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
        if (genericDisplay.getStreamClient().reTry(delay: 5000, reason: reason)) {
            toastText = "Retry"
            isShowingToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isShowingToast = false
            }
        } else {
            genericDisplay.stopStream()
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
    
    
    @State private var endpoint = ""
    @State private var bStreamText = "Start stream"
    @State private var bRecordText = "Start record"
    @State private var isShowingToast = false
    @State private var toastText = ""
    @State private var bitrateText = ""
    @State private var filePath: URL? = nil

    @State private var genericDisplay: GenericDisplay!
    
    var body: some View {
        ZStack {
            let camera = CameraUIView()
            camera.edgesIgnoringSafeArea(.all)
            
            camera.onAppear {
                genericDisplay = GenericDisplay(connectChecker: self)
                genericDisplay.getStreamClient().setRetries(reTries: 10)
            }
            camera.onDisappear {
                if (genericDisplay.isStreaming()) {
                    genericDisplay.stopStream()
                }
            }
            
            VStack {
                HStack {
                    Spacer()
                    Menu("Filters") {
                        /*
                        Button(action: {
                            rtspDisplay.metalInterface.clearFilters()
                        }) {
                            Text("No filter")
                        }
                        Button(action: {
                            rtspDisplay.metalInterface.setFilter(baseFilterRender: GreyScaleFilterRender())
                        }) {
                            Text("GreyScale")
                        }
                        Button(action: {
                            rtspDisplay.metalInterface.setFilter(baseFilterRender: SepiaFilterRender())
                        }) {
                            Text("Sepia")
                        }
                         */
                    }
                }.padding(.trailing, 16)
                TextField("protocol://ip:port/app/streamname", text: $endpoint)
                    .padding()
                    .foregroundColor(Color.init(hex: "#e74c3c"))
                    .padding(.top, 24)
                    .padding(.horizontal)
                    .keyboardType(.default)
                    .multilineTextAlignment(.center)
                Text(bitrateText).foregroundColor(Color.init(hex: "#e74c3c"))
                Spacer()
                HStack(alignment: .center, spacing: 16, content: {
                    Button(bRecordText) {
                        if (!genericDisplay.isRecording()) {
                            if (genericDisplay.prepareAudio() && genericDisplay.prepareVideo()) {
                                let url = getVideoUrl()
                                if (url != nil) {
                                    filePath = url
                                    genericDisplay.startRecord(path: url!)
                                    bRecordText = "Stop record"
                                }
                            }
                        } else {
                            genericDisplay.stopRecord()
                            if (filePath != nil) {
                                saveVideoToGallery(videoURL: filePath!)
                                filePath = nil
                            }
                            bRecordText = "Start record"
                        }
                    }.font(.system(size: 20, weight: Font.Weight.bold))
                    Button(bStreamText) {
                        let endpoint = endpoint
                        if (!genericDisplay.isStreaming()) {
                            if (genericDisplay.prepareAudio() && genericDisplay.prepareVideo()) {
                                genericDisplay.startStream(endpoint: endpoint)
                                bStreamText = "Stop stream"
                            }
                        } else {
                            genericDisplay.stopStream()
                            bStreamText = "Start stream"
                            bitrateText = ""
                        }
                    }.font(.system(size: 20, weight: Font.Weight.bold))
                }).padding(.bottom, 24)
            }.frame(alignment: .bottom)
        }.showToast(text: toastText, isShowing: $isShowingToast)
    }
}

#Preview {
    ScreenSwiftUIView()
}
