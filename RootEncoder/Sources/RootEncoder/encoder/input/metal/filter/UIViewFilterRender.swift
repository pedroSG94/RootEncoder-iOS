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
    
    public init(view: UIView) {
        self.view = view
    }
    
    public func draw(image: CIImage, orientation: CGImagePropertyOrientation) -> CIImage {
        let filterView = toCIImage(view: view)
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
    
    private func toCIImage(view: UIView) -> CIImage? {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let image = image else { return nil }
        return CIImage(image: image)
    }
}
