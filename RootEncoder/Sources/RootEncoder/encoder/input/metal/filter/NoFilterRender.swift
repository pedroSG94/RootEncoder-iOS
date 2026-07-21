//
//  Created by Pedro on 09/07/2026.
//
import Common
import Foundation
import CoreImage

public class NoFilterRender: BaseFilterRender {
    
    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "NoFilter")
    }
}
