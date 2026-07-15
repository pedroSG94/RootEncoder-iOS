import Foundation
import Metal

public class LamoishFilterRender: BaseFilterRender {

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "LamoishFilter")
    }
}
