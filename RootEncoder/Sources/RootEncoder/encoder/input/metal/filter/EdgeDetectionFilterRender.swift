import Foundation
import Metal

public class EdgeDetectionFilterRender: BaseShaderFilterRender {

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "EdgeDetectionFilter")
    }
}
