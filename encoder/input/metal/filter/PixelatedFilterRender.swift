import common
import Foundation
import Metal

public class PixelatedFilterRender: BaseFilterRender {

    public var pixelated: Float = 0.01

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "PixelatedFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&pixelated, length: MemoryLayout<Float>.size, index: 0)
    }
}
