import Foundation
import Metal

public class RGBSaturationFilterRender: BaseFilterRender {

    //saturation of each color in percent (0.0 to 1.0)
    public var saturation = SIMD3<Float>(1, 1, 1)

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "RgbSaturationFilter")
    }

    public func setRGBSaturation(r: Float, g: Float, b: Float) {
        saturation = SIMD3<Float>(r, g, b)
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&saturation, length: MemoryLayout<SIMD3<Float>>.size, index: 0)
    }
}
