//
//  Created by Pedro  on 24/07/26.
//

import common
import Foundation
import CoreImage
import UIKit

public class ImageFilterRender: BaseObjectFilterRender {

    public func setImage(image: UIImage) {
        setObject(image: toCIImage(image: image))
    }

    private func toCIImage(image: UIImage) -> CIImage? {
        guard let cgImage = image.cgImage else { return image.ciImage }
        return CIImage(cgImage: cgImage).oriented(toCGOrientation(orientation: image.imageOrientation))
    }

    private func toCGOrientation(orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
