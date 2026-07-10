//
//  RippleFilterRender.swift
//  RootEncoder
//
//  Ported from Android RippleFilterRender
//

import Foundation
import Metal

public class RippleFilterRender: BaseShaderFilterRender {

    public var speed: Float = 15
    private let startTime = Date()
    private var resolution = SIMD2<Float>(640, 480)

    public override func initMetal(width: Int, height: Int, device: MTLDevice) {
        resolution = SIMD2<Float>(Float(width), Float(height))
        super.initMetal(width: width, height: height, device: device)
    }

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "RippleFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        var time = Float(-startTime.timeIntervalSinceNow)
        encoder.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.size, index: 0)
        encoder.setFragmentBytes(&speed, length: MemoryLayout<Float>.size, index: 1)
        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 2)
    }
}
