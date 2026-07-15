import Foundation
import Metal

public class CropFilterRender: BaseShaderFilterRender {

    private var area = SIMD4<Float>(0, 0, 1, 1)

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "CropFilter")
    }

    /**
     Set crop area in percentage (0 to 100). Starting from top left corner.
     */
    public func setCropArea(offsetX: Float, offsetY: Float, width: Float, height: Float) {
        area = SIMD4<Float>(offsetX / 100, offsetY / 100, width / 100, height / 100)
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&area, length: MemoryLayout<SIMD4<Float>>.size, index: 0)
    }
}
