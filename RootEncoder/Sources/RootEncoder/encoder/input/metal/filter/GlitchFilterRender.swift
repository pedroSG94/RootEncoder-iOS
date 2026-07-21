import Common
import Foundation
import Metal

public class GlitchFilterRender: BaseFilterRender {

    private let startTime = Date()

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "GlitchFilter")
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        var time = Float(-startTime.timeIntervalSinceNow)
        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
    }
}
