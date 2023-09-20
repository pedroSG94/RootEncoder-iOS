//
//  CameraUIView.swift
//  app
//
//  Created by Pedro  on 20/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import SwiftUI

struct CameraUIView: UIViewRepresentable {
    
    let view = UIView()
    
    public func makeUIView(context: Context) -> UIView {
        view.backgroundColor = .black // Puedes cambiar el color de fondo según tus preferencias
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        // Aquí puedes realizar cualquier actualización necesaria en la UIView
    }
}
