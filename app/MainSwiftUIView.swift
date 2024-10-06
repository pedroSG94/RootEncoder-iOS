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
            VStack(spacing: 64) {
                NavigationLink(destination: StreamSwiftUIView()) {
                    Text("Stream")
                }
                NavigationLink(destination: CameraSwiftUIView()) {
                    Text("Camera")
                }
                NavigationLink(destination: ScreenSwiftUIView()) {
                    Text("Screen")
                }
            }
        }.accentColor(Color.init(hex: "#e74c3c")).navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    MainSwiftUIView()
}
