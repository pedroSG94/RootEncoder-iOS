//
//  MetalViewport.swift
//  encoder
//
//  Created by Pedro  on 4/11/23.
//

import Foundation

public struct MetalViewport {
    public let positionX: CGFloat
    public let positionY: CGFloat
    public let scaleX: CGFloat
    public let scaleY: CGFloat
    
    public init(positionX: CGFloat, positionY: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        self.positionX = positionX
        self.positionY = positionY
        self.scaleX = scaleX
        self.scaleY = scaleY
    }
}
