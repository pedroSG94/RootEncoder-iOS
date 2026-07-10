//
//  NoiseFilterRender.swift
//  RootEncoder
//
//  Ported from Android NoiseFilterRender
//

import Foundation
import Metal

public class NoiseFilterRender: BaseShaderFilterRender {

    public var strength: Float = 16
    private let startTime = Date()

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "NoiseFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        var time = Float(-startTime.timeIntervalSinceNow)
        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        encoder.setFragmentBytes(&strength, length: MemoryLayout<Float>.size, index: 1)
    }
}
