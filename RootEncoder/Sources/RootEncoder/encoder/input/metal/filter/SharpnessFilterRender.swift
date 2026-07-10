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
    private var resolution = SIMD2<Float>(640, 480)

    public override func initMetal(width: Int, height: Int, device: MTLDevice) {
        resolution = SIMD2<Float>(Float(width), Float(height))
        super.initMetal(width: width, height: height, device: device)
    }

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "SharpnessFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.size, index: 0)
        encoder.setFragmentBytes(&sharpness, length: MemoryLayout<Float>.size, index: 1)
    }
}
