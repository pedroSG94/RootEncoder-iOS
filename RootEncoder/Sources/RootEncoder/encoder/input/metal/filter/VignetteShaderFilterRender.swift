//
//  VignetteShaderFilterRender.swift
//  RootEncoder
//
//  Created by Pedro  on 8/7/25.
//

import Foundation
import Metal


open class VignetteShaderFilterRender: BaseShaderFilterRender {

    public var intensity: Float

    public init(intensity: Float = 1.5) {
        self.intensity = intensity
        super.init()
    }

    open override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex")
            + MetalUtils.readShader(name: "VignetteFilter")
    }

    open override func drawFilter(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&intensity, length: MemoryLayout<Float>.size, index: 0)
    }
}
