//
//  BeautyFilterRender.swift
//  RootEncoder
//
//  Ported from Android BeautyFilterRender
//

import Foundation
import Metal

public class BeautyFilterRender: BaseShaderFilterRender {

    private var resolution = SIMD2<Float>(2 / 640, 2 / 480)

    public override func initMetal(width: Int, height: Int, device: MTLDevice) {
        resolution = SIMD2<Float>(2 / Float(width), 2 / Float(height))
        super.initMetal(width: width, height: height, device: device)
    }

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "BeautyFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.size, index: 0)
    }
}
