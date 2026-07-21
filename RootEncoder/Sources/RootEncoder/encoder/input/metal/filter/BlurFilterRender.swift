import Common
import Foundation
import Metal

public class BlurFilterRender: BaseFilterRender {

    public var blur: Float = 10
    public var radius: Float = 0.03

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "BlurFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&blur, length: MemoryLayout<Float>.size, index: 0)
        encoder.setFragmentBytes(&radius, length: MemoryLayout<Float>.size, index: 1)
    }
}
