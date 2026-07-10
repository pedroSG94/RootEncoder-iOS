//
//  RotationFilterRender.swift
//  RootEncoder
//
//  Ported from Android RotationFilterRender
//

import Foundation
import Metal

public class RotationFilterRender: BaseShaderFilterRender {

    //rotation in degrees
    public var rotation: Int = 0
    public var horizontalFlip = false
    public var verticalFlip = false

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "RotationFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        var radians = Float(rotation) * Float.pi / 180
        var flips = SIMD2<Float>(horizontalFlip ? 1 : 0, verticalFlip ? 1 : 0)
        encoder.setFragmentBytes(&radians, length: MemoryLayout<Float>.size, index: 0)
        encoder.setFragmentBytes(&flips, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
    }
}
