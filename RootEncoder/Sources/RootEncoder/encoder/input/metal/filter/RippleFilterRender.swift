import Foundation
import Metal

public class RippleFilterRender: BaseShaderFilterRender {

    public var speed: Float = 15
    private let startTime = Date()

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "RippleFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        var time = Float(-startTime.timeIntervalSinceNow)
        var res = resolution
        encoder.setFragmentBytes(&res, length: MemoryLayout<SIMD2<Float>>.size, index: 0)
        encoder.setFragmentBytes(&speed, length: MemoryLayout<Float>.size, index: 1)
        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 2)
    }
}
