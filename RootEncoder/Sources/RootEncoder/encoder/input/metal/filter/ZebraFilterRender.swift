import Foundation
import Metal

public class ZebraFilterRender: BaseShaderFilterRender {

    public var levels: Float = 8
    private let startTime = Date()

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "ZebraFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        var time = Float(-startTime.timeIntervalSinceNow)
        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        encoder.setFragmentBytes(&levels, length: MemoryLayout<Float>.size, index: 1)
    }
}
