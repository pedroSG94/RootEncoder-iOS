//
//  ColorFilterRender.swift
//  RootEncoder
//
//  Ported from Android ColorFilterRender
//

import Foundation
import Metal

public class ColorFilterRender: BaseShaderFilterRender {

    //color in percent (0.0 to 1.0)
    public var color = SIMD3<Float>(0, 0, 1)

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "ColorFilter")
    }

    public func setRGBColor(r: Int, g: Int, b: Int) {
        color = SIMD3<Float>(Float(r) / 255, Float(g) / 255, Float(b) / 255)
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&color, length: MemoryLayout<SIMD3<Float>>.size, index: 0)
    }
}
