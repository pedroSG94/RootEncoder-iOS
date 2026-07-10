//
//  EarlyBirdFilterRender.swift
//  RootEncoder
//
//  Ported from Android EarlyBirdFilterRender
//

import Foundation
import Metal

public class EarlyBirdFilterRender: BaseShaderFilterRender {

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "EarlyBirdFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        var res = resolution
        encoder.setFragmentBytes(&res, length: MemoryLayout<SIMD2<Float>>.size, index: 0)
    }
}
