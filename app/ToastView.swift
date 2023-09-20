//
//  ToastView.swift
//  app
//
//  Created by Pedro  on 20/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import SwiftUI

struct Toast<Presenting>: View where Presenting: View {
    let presenting: Presenting
    let text: String
    @Binding var isShowing: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                presenting
                if isShowing {
                    VStack {
                        Text(text)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                    }
                    .frame(width: geometry.size.width / 2,
                           height: geometry.size.height / 5)
                    .background(Color.clear)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.4))
                }
            }
        }
    }
}

extension View {
    func showToast(text: String, isShowing: Binding<Bool>) -> some View {
        Toast(presenting: self, text: text, isShowing: isShowing)
    }
}
