import Foundation
import Metal

public class CircleFilterRender: BaseFilterRender {

    public var radius: Float = 0.5
    //center of the circle in percent (0.0 to 1.0)
    public var center = SIMD2<Float>(0.5, 0.5)

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "CircleFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        var res = resolution
        encoder.setFragmentBytes(&radius, length: MemoryLayout<Float>.size, index: 0)
        encoder.setFragmentBytes(&center, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
        encoder.setFragmentBytes(&res, length: MemoryLayout<SIMD2<Float>>.size, index: 2)
    }
}
