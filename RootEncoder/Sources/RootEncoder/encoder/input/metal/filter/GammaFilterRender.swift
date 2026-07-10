//
//  GammaFilterRender.swift
//  RootEncoder
//
//  Ported from Android GammaFilterRender
//

import Foundation
import Metal

public class GammaFilterRender: BaseShaderFilterRender {

    public var gamma: Float = 0.5

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "GammaFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&gamma, length: MemoryLayout<Float>.size, index: 0)
    }
}
