//
//  File.swift
//  
//
//  Created by Pedro  on 9/8/24.
//

import Foundation


public class Sprite {
    
    private var positionX: Double = 0
    private var positionY: Double = 0
    private var scaleX: Double = 100
    private var scaleY: Double = 100
    private var rotation: Double = 0
    
    public func translateTo(translation: TranslateTo) {
        switch translation {
        case .CENTER:
            positionX = (100 - scaleX) / 2
            positionY = (100 - scaleY) / 2
        case .LEFT:
            positionX = 0
            positionY = (100 - scaleY) / 2
        case .RIGHT:
            positionX = 100 - scaleX
            positionY = (100 - scaleY) / 2
        case .TOP:
            positionX = (100 - scaleX) / 2
            positionY = 0
        case .BOTTOM:
            positionX = (100 - scaleX) / 2
            positionY = 100 - scaleY
        case .TOP_LEFT:
            positionX = 0
            positionY = 0
        case .TOP_RIGHT:
            positionX = 100 - scaleX
            positionY = 0
        case .BOTTOM_LEFT:
            positionX = 0
            positionY = 100 - scaleY
        case .BOTTOM_RIGHT:
            positionX = 100 - scaleX
            positionY = 100 - scaleY
        }
    }
    
    public func reset() {
        positionX = 0
        positionY = 0
        scaleX = 100
        scaleY = 100
        rotation = 0
    }
    
    public func getCalculatedScale(image: CGRect, filter: CGRect) -> CGSize {
        let filterWidth = filter.width
        let filterHeight = filter.height
        
        let imageWidth = image.width
        let imageHeight = image.height
        
        let scaleX = imageWidth / filterWidth
        let scaleY = imageHeight / filterHeight
        
        let resultX = scaleX / (100 / self.scaleX)
        let resultY = scaleY / (100 / self.scaleY)
        return CGSize(width: resultX, height: resultY)
    }
    
    public func getCalculatedPosition(image: CGRect, filter: CGRect) -> CGSize {
        let resultX: Double = image.width * positionX / 100
        let resultY: Double = (image.height - image.height * (scaleY / 100)) - (image.height * positionY / 100)
        return CGSize(width: resultX, height: resultY)
    }
    
    public func getCalculatedRotation() -> Double {
        return self.rotation * .pi / 180
    }
    
    public func setPosition(x: Double, y: Double) {
        positionX = x
        positionY = y
    }
    
    public func setScale(x: Double, y: Double) {
        scaleX = x
        scaleY = y
    }
    
    public func setRotation(rotation: Double) {
        self.rotation = rotation
    }
}
