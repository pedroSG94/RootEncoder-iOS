//
//  MainSwiftUIView.swift
//  app
//
//  Created by Pedro  on 20/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import SwiftUI

struct MainSwiftUIView: View {
        
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                NavigationLink(destination: RtmpSwiftUIView()) {
                    Text("RTMP")
                }
                NavigationLink(destination: RtspSwiftUIView()) {
                    Text("RTSP")
                }
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    MainSwiftUIView()
}
