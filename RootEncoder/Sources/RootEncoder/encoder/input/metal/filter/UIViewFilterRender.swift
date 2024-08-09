//
//  ViewFilterRender.swift
//
//
//  Created by Pedro  on 4/8/24.
//

import Foundation
import CoreImage
import SwiftUI

public class ViewFilterRender: BaseFilterRender {
    
    private let view: UIView
    private let sprite = Sprite()
    
    public init(view: UIView) {
        self.view = view
    }
    
    public func draw(image: CIImage, orientation: CGImagePropertyOrientation) -> CIImage {
        let filterView = toCIImage(view: view)
        guard let filterView = filterView else { return image }
        
        let scale = sprite.getCalculatedScale(image: image.extent, filter: filterView.extent)
        let position = sprite.getCalculatedPosition(image: image.extent, filter: filterView.extent)
        let rotation = sprite.getCalculatedRotation()
        
        let scaled = filterView
            .transformed(by: CGAffineTransform(scaleX: scale.width, y: scale.height))
            .transformed(by: CGAffineTransform(rotationAngle: rotation))
            .transformed(by: CGAffineTransform(translationX: position.width, y: position.height))
        return scaled.composited(over: image)
    }
    
    private func toCIImage(view: UIView) -> CIImage? {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let image = image else { return nil }
        return CIImage(image: image)
    }
    
    public func setScale(percentX: Double, percentY: Double) {
        sprite.setScale(x: percentX, y: percentY)
    }
    
    public func setPosition(percentX: Double, percentY: Double) {
        sprite.setPosition(x: percentX, y: percentY)
    }
    
    public func translateTo(translation: TranslateTo) {
        sprite.translateTo(translation: translation)
    }
    
    public func setRotation(rotation: Double) {
        sprite.setRotation(rotation: rotation)
    }
}
