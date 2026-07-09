//
//  BaseFilterRender.swift
//  encoder
//
//  Created by Pedro  on 4/11/23.
//

import Foundation
import CoreImage

open class BaseFilterRender {
    public var renderMode = RenderMode.ALL
    
    public init() { }
    
    open func draw(image: CIImage, orientation: CGImagePropertyOrientation, isPreview: Bool) -> CIImage {
        fatalError("draw method must be overriden")
    }
    open func setMetalInfo(commandQueue: any MTLCommandQueue, context: CIContext) { }
    open func initMetal(width: Int, height: Int, device: MTLDevice) { }
}
