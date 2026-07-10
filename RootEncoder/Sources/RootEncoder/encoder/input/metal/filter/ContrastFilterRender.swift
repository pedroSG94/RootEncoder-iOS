//
//  ContrastFilterRender.swift
//  RootEncoder
//
//  Ported from Android ContrastFilterRender
//

import Foundation
import Metal

public class ContrastFilterRender: BaseShaderFilterRender {

    public var contrast: Float = 0.5

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "ContrastFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&contrast, length: MemoryLayout<Float>.size, index: 0)
    }
}
