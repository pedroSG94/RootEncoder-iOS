import Foundation
import Metal

public class CartoonFilterRender: BaseShaderFilterRender {

    public var cartoon: Float = 0.007

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "CartoonFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&cartoon, length: MemoryLayout<Float>.size, index: 0)
    }
}
