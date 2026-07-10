//
//  SnowFilterRender.swift
//  RootEncoder
//
//  Ported from Android SnowFilterRender
//

import Foundation
import Metal

public class SnowFilterRender: BaseShaderFilterRender {

    public var layers: Float = 5
    public var depth: Float = 0.5
    public var snowWidth: Float = 0.6
    public var speed: Float = 0.6
    private let startTime = Date()

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "SnowFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        var time = Float(-startTime.timeIntervalSinceNow)
        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        encoder.setFragmentBytes(&layers, length: MemoryLayout<Float>.size, index: 1)
        encoder.setFragmentBytes(&depth, length: MemoryLayout<Float>.size, index: 2)
        encoder.setFragmentBytes(&snowWidth, length: MemoryLayout<Float>.size, index: 3)
        encoder.setFragmentBytes(&speed, length: MemoryLayout<Float>.size, index: 4)
    }
}
