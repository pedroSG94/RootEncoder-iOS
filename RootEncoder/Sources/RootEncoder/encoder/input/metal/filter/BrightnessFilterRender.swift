import Foundation
import Metal

public class BrightnessFilterRender: BaseShaderFilterRender {

    public var brightness: Float = 0.5

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "BrightnessFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&brightness, length: MemoryLayout<Float>.size, index: 0)
    }
}
