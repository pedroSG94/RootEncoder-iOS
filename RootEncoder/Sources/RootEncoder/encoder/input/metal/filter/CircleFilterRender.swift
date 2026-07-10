//
//  CircleFilterRender.swift
//  RootEncoder
//
//  Ported from Android CircleFilterRender
//

import Foundation
import Metal

public class CircleFilterRender: BaseShaderFilterRender {

    public var radius: Float = 0.5
    //center of the circle in percent (0.0 to 1.0)
    public var center = SIMD2<Float>(0.5, 0.5)
    private var resolution = SIMD2<Float>(640, 480)

    public override func initMetal(width: Int, height: Int, device: MTLDevice) {
        resolution = SIMD2<Float>(Float(width), Float(height))
        super.initMetal(width: width, height: height, device: device)
    }

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "CircleFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&radius, length: MemoryLayout<Float>.size, index: 0)
        encoder.setFragmentBytes(&center, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
        encoder.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.size, index: 2)
    }
}
