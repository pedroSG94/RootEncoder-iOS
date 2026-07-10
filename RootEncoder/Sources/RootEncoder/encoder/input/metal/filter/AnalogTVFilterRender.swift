//
//  AnalogTVFilterRender.swift
//  RootEncoder
//
//  Ported from Android AnalogTVFilterRender
//

import Foundation
import Metal

public class AnalogTVFilterRender: BaseShaderFilterRender {

    private let startTime = Date()
    private var resolution = SIMD2<Float>(640, 480)

    public override func initMetal(width: Int, height: Int, device: MTLDevice) {
        resolution = SIMD2<Float>(Float(width), Float(height))
        super.initMetal(width: width, height: height, device: device)
    }

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "AnalogTvFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        var time = Float(-startTime.timeIntervalSinceNow)
        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        encoder.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
    }
}
