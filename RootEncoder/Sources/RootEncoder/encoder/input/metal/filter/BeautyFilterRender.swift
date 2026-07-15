import Foundation
import Metal

public class BeautyFilterRender: BaseFilterRender {

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "BeautyFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        var res = SIMD2<Float>(2 / resolution.x, 2 / resolution.y)
        encoder.setFragmentBytes(&res, length: MemoryLayout<SIMD2<Float>>.size, index: 0)
    }
}
