//
//  DistortedTvFilterRender.swift
//  RootEncoder
//
//  Ported from Android DistortedTvFilterRender
//

import Foundation
import Metal

public class DistortedTvFilterRender: BaseShaderFilterRender {

    private let startTime = Date()

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "DistortedTvFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        var time = Float(-startTime.timeIntervalSinceNow)
        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
    }
}
