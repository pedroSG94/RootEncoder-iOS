//
//  File.swift
//
//
//  Created by Pedro  on 4/8/24.
//

import Foundation
import CoreImage
import SwiftUI

public class ViewFilterRender: BaseFilterRender {
    
    private let view: UIView
    
    public init(view: UIView) {
        self.view = view
    }
    
    public func draw(image: CIImage, orientation: CGImagePropertyOrientation) -> CIImage {
        let filterView = view.asCIImage()
        guard let filterView = filterView else { return image }
        let filterWidth = filterView.extent.width
        let filterHeight = filterView.extent.height
        
        let imageWidth = image.extent.width
        let imageHeight = image.extent.height
        
        let scaleX = imageWidth / filterWidth
        let scaleY = imageHeight / filterHeight
        
        let scaled = filterView.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        return scaled.composited(over: image)
    }
}

extension UIView {
    func asUIImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        drawHierarchy(in: bounds, afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    func asCIImage() -> CIImage? {
        let uiImage = self.asUIImage()
        guard let image = uiImage else { return nil }
        return CIImage(image: image)
    }
}
