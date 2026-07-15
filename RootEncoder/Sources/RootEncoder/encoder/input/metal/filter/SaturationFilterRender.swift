import Foundation
import Metal

public class SaturationFilterRender: BaseShaderFilterRender {

    private var saturation: Float = -0.5
    private var shift: Float = 1.0 / 255.0
    private var weights = SIMD3<Float>(0.3086, 0.6094, 0.0820)
    private var exponents = SIMD3<Float>(0, 0, 0)

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "SaturationFilter")
    }

    /**
     @param saturation between -1.0 and 1.0, 0.0 means no change while -1.0 indicates full desaturation (grayscale)
     */
    public func setSaturation(saturation: Float) {
        if saturation > 0.0 {
            exponents = SIMD3<Float>((0.9 * saturation) + 1.0, (2.1 * saturation) + 1.0, (2.7 * saturation) + 1.0)
            self.saturation = saturation
        } else {
            self.saturation = saturation + 1.0
        }
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&shift, length: MemoryLayout<Float>.size, index: 0)
        encoder.setFragmentBytes(&weights, length: MemoryLayout<SIMD3<Float>>.size, index: 1)
        encoder.setFragmentBytes(&exponents, length: MemoryLayout<SIMD3<Float>>.size, index: 2)
        encoder.setFragmentBytes(&saturation, length: MemoryLayout<Float>.size, index: 3)
    }
}
