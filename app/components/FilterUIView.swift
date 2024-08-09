//
//  FilterUIView.swift
//  app
//
//  Created by Pedro  on 20/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import SwiftUI
import RootEncoder
import UIKit

struct FilterUIView: UIViewRepresentable {
    
    let view = Bundle.main.loadNibNamed("ViewFilter", owner: nil, options: nil)![0] as! UIView
    
    public func makeUIView(context: Context) -> UIView {
        view.frame = .zero
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
    }
}
