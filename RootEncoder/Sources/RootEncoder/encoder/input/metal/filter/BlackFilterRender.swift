import Common
import Foundation
import Metal

public class BlackFilterRender: BaseFilterRender {

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "BlackFilter")
    }
}
