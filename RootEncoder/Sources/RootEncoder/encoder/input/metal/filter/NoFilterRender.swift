//
//  Created by Pedro on 09/07/2026.
//
import Foundation
import CoreImage

public class NoFilterRender: BaseFilterRender {
    
    public override func draw(image: CIImage, orientation: CGImagePropertyOrientation, isPreview: Bool) -> CIImage {
        return image
    }
}
