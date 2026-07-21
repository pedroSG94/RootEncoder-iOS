//
//  Created by Pedro  on 4/11/23.
//

import Common
import Foundation
import Metal

public class GreyScaleFilterRender: BaseFilterRender {

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "GreyScaleFilter")
    }
}
