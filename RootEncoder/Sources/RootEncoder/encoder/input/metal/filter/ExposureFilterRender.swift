//
//  ExposureFilterRender.swift
//  RootEncoder
//
//  Ported from Android ExposureFilterRender
//

import Foundation
import Metal

public class ExposureFilterRender: BaseShaderFilterRender {

    public var exposure: Float = 0.5

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "ExposureFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&exposure, length: MemoryLayout<Float>.size, index: 0)
    }
}
