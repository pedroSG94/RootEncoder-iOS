import Foundation
import Metal

public class SwirlFilterRender: BaseShaderFilterRender {

    public var radius: Float = 0.2
    //center of the effect in percent (0.0 to 1.0)
    public var center = SIMD2<Float>(0.5, 0.5)
    private var time: Float = 0
    private var lastTime = Date()
    private var isIncrement = true

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "SwirlFilter")
    }

    private func getTime() -> Float {
        let now = Date()
        let interval = Float(now.timeIntervalSince(lastTime))
        lastTime = now
        if isIncrement {
            time += interval
        } else {
            time -= interval
        }
        if time > 2 {
            isIncrement = false
        } else if time < -2 {
            isIncrement = true
        }
        return time
    }

    public override func drawFilter(encoder: MTLRenderCommandEncoder) {
        var time = getTime()
        var res = resolution
        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        encoder.setFragmentBytes(&res, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
        encoder.setFragmentBytes(&radius, length: MemoryLayout<Float>.size, index: 2)
        encoder.setFragmentBytes(&center, length: MemoryLayout<SIMD2<Float>>.size, index: 3)
    }
}
