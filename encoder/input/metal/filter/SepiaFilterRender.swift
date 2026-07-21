//
//  Created by Pedro  on 5/4/24.
//

import common
import Foundation
import Metal

public class SepiaFilterRender: BaseFilterRender {

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "SepiaFilter")
    }
}
