//
//  CameraUIView.swift
//  app
//
//  Created by Pedro  on 20/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import SwiftUI
import RootEncoder
import MetalKit

struct MetalUIView: UIViewRepresentable {
    
    let view = MTKView(frame: .zero)
    
    public func makeUIView(context: Context) -> UIView {
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
    }
}
