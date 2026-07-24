import common
import Foundation
import Metal

public class DuotoneFilterRender: BaseFilterRender {

    //colors in percent (0.0 to 1.0)
    public var color = SIMD3<Float>(0, 1, 0)
    public var color2 = SIMD3<Float>(0, 0, 1)

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "DuotoneFilter")
    }

    public func setRGBColor(r: Int, g: Int, b: Int, r2: Int, g2: Int, b2: Int) {
        color = SIMD3<Float>(Float(r) / 255, Float(g) / 255, Float(b) / 255)
        color2 = SIMD3<Float>(Float(r2) / 255, Float(g2) / 255, Float(b2) / 255)
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&color, length: MemoryLayout<SIMD3<Float>>.size, index: 0)
        encoder.setFragmentBytes(&color2, length: MemoryLayout<SIMD3<Float>>.size, index: 1)
    }
}
