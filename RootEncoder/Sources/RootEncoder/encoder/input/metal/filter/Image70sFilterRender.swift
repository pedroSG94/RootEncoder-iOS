import Foundation
import Metal

public class Image70sFilterRender: BaseFilterRender {

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "Image70sFilter")
    }
}
