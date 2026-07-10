//
//  SharpnessFilterRender.swift
//  RootEncoder
//
//  Ported from Android SharpnessFilterRender
//

import Foundation
import Metal

public class SharpnessFilterRender: BaseShaderFilterRender {

    public var sharpness: Float = 16

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "SharpnessFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        var res = resolution
        encoder.setFragmentBytes(&res, length: MemoryLayout<SIMD2<Float>>.size, index: 0)
        encoder.setFragmentBytes(&sharpness, length: MemoryLayout<Float>.size, index: 1)
    }
}
