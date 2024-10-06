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

struct StreamSwiftUIView: View, ConnectChecker {
    
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
        if (rtmpStream.getStreamClient().reTry(delay: 5000, reason: reason)) {
            toastText = "Retry"
            isShowingToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isShowingToast = false
            }
        } else {
            rtmpStream.stopStream()
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
    
    
    @State private var endpoint = "rtmp://192.168.0.176/live/pedro"
    @State private var bStreamText = "Start stream"
    @State private var bRecordText = "Start record"
    @State private var isShowingToast = false
    @State private var toastText = ""
    @State private var bitrateText = ""
    @State private var filePath: URL? = nil
    @State private var rtmpStream: RtmpStream!
    
    @State private var scale: CGFloat = 1.0
    
    private var zoomGesture: some Gesture {
        MagnificationGesture().onChanged { value in
            if let camera = rtmpStream.videoSource as? CameraSource {
                camera.setZoom(level: value)
            }
        }.onEnded { value in
            if let camera = rtmpStream.videoSource as? CameraSource {
                camera.setZoom(level: value)
            }
        }
    }
    
    var body: some View {
        ZStack {
            let filter = FilterUIView()
            filter.edgesIgnoringSafeArea(.all)
            
            let camera = MetalUIView()
            let cameraView = camera.view
            camera.edgesIgnoringSafeArea(.all)
            camera.background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            rtmpStream = RtmpStream(connectChecker: self)
                            let _ = rtmpStream.prepareAudio(sampleRate: 32000, isStereo: true, bitrate: 128 * 1000) && rtmpStream.prepareVideo(width: 640, height: 480, bitrate: 1200 * 1000)
                            rtmpStream.startPreview(view: cameraView)
                        }
                        .onChange(of: geometry.size) { newSize in
                            rtmpStream.metalInterface.setPreviewSize(width: newSize.width, height: newSize.height)
                        }
                        .onDisappear {
                            if (rtmpStream.isStreaming()) {
                                rtmpStream.stopStream()
                            }
                            if (rtmpStream.isRecording()) {
                                rtmpStream.stopRecord()
                            }
                            if (rtmpStream.isOnPreview()) {
                                rtmpStream.stopPreview()
                            }
                        }
                }
            )
            
            VStack {
                HStack {
                    Spacer()
                    Menu("Filters") {
                        Button(action: {
                            rtmpStream.metalInterface.clearFilters()
                        }) {
                            Text("No filter")
                        }
                        Button(action: {
                            rtmpStream.metalInterface.setFilter(baseFilterRender: GreyScaleFilterRender())
                        }) {
                            Text("GreyScale")
                        }
                        Button(action: {
                            rtmpStream.metalInterface.setFilter(baseFilterRender: SepiaFilterRender())
                        }) {
                            Text("Sepia")
                        }
                        Button(action: {
                            let filterView = ViewFilterRender(view: filter.view)
                            rtmpStream.metalInterface.setFilter(baseFilterRender: filterView)
                            filterView.setScale(percentX: 100, percentY: 100)
                            filterView.translateTo(translation: .CENTER)
                        }) {
                            Text("View")
                        }
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
                        if (!rtmpStream.isRecording()) {
                            let url = getVideoUrl()
                            if (url != nil) {
                                filePath = url
                                rtmpStream.startRecord(path: url!)
                                bRecordText = "Stop record"
                            }
                        } else {
                            rtmpStream.stopRecord()
                            if (filePath != nil) {
                                saveVideoToGallery(videoURL: filePath!)
                                filePath = nil
                            }
                            bRecordText = "Start record"
                        }
                    }.font(.system(size: 20, weight: Font.Weight.bold))
                    Button(bStreamText) {
                        let endpoint = endpoint
                        if (!rtmpStream.isStreaming()) {
                            rtmpStream.startStream(endpoint: endpoint)
                            bStreamText = "Stop stream"
                        } else {
                            rtmpStream.stopStream()
                            bStreamText = "Start stream"
                            bitrateText = ""
                        }
                    }.font(.system(size: 20, weight: Font.Weight.bold))
                    Button("Switch camera") {
                        if let camera = rtmpStream.videoSource as? CameraSource {
                            camera.switchCamera()
                        }
                    }.font(.system(size: 20, weight: Font.Weight.bold))
                }).padding(.bottom, 24)
            }.frame(alignment: .bottom)
        }.gesture(zoomGesture).showToast(text: toastText, isShowing: $isShowingToast)
    }
}

#Preview {
    CameraSwiftUIView()
}

