import Foundation
import Metal

public class TemperatureFilterRender: BaseShaderFilterRender {

    //temperature between -1.0 (cold) and 1.0 (warm)
    public var temperature: Float = 0.8

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "TemperatureFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&temperature, length: MemoryLayout<Float>.size, index: 0)
    }
}
