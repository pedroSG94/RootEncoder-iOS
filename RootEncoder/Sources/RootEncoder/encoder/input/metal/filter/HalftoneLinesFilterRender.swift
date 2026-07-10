//
//  HalftoneLinesFilterRender.swift
//  RootEncoder
//
//  Ported from Android HalftoneLinesFilterRender
//

import Foundation
import Metal

public class HalftoneLinesFilterRender: BaseShaderFilterRender {

    //mode from 1 to 7
    public var mode: Float = 1
    public var rows: Float = 40
    public var rotation: Float = 0
    public var antialias: Float = 0.2
    public var sampleDist = SIMD2<Float>(2, 2)
    private var resolution = SIMD2<Float>(640, 480)

    public override func initMetal(width: Int, height: Int, device: MTLDevice) {
        resolution = SIMD2<Float>(Float(width), Float(height))
        super.initMetal(width: width, height: height, device: device)
    }

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "HalftoneLinesFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.size, index: 0)
        encoder.setFragmentBytes(&mode, length: MemoryLayout<Float>.size, index: 1)
        encoder.setFragmentBytes(&rows, length: MemoryLayout<Float>.size, index: 2)
        encoder.setFragmentBytes(&rotation, length: MemoryLayout<Float>.size, index: 3)
        encoder.setFragmentBytes(&antialias, length: MemoryLayout<Float>.size, index: 4)
        encoder.setFragmentBytes(&sampleDist, length: MemoryLayout<SIMD2<Float>>.size, index: 5)
    }
}
