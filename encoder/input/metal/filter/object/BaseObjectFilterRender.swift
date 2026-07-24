//
//  Created by Pedro  on 24/07/26.
//

import common
import Foundation
import CoreImage

open class BaseObjectFilterRender: BaseFilterRender {

    private let lock = NSLock()
    private var objectImage: CIImage? = nil
    private var alpha: Float = 1
    private let sprite = Sprite()

    public override func draw(image: CIImage, orientation: CGImagePropertyOrientation, isPreview: Bool) -> CIImage {
        lock.lock()
        let object = objectImage
        lock.unlock()
        guard let object = object, alpha > 0 else { return image }

        let scale = sprite.getCalculatedScale(image: image.extent, filter: object.extent)
        let position = sprite.getCalculatedPosition(image: image.extent, filter: object.extent)
        let rotation = sprite.getCalculatedRotation()

        var result = object.transformed(by: CGAffineTransform(scaleX: scale.width, y: scale.height))
        if rotation != 0 {
            // rotate around the object center like Android Sprite
            let center = CGPoint(x: result.extent.midX, y: result.extent.midY)
            result = result
                .transformed(by: CGAffineTransform(translationX: -center.x, y: -center.y))
                .transformed(by: CGAffineTransform(rotationAngle: rotation))
                .transformed(by: CGAffineTransform(translationX: center.x, y: center.y))
        }
        result = result.transformed(by: CGAffineTransform(translationX: position.width, y: position.height))
        if alpha < 1 {
            let alpha = CGFloat(alpha)
            result = result.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: alpha, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: alpha, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: alpha, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: alpha)
            ])
        }
        return result.composited(over: image).cropped(to: image.extent)
    }

    public func setObject(image: CIImage?) {
        var image = image
        if let value = image, value.extent.origin != .zero {
            image = value.transformed(by: CGAffineTransform(translationX: -value.extent.minX, y: -value.extent.minY))
        }
        lock.lock()
        objectImage = image
        lock.unlock()
    }

    public func setAlpha(alpha: Float) {
        self.alpha = alpha
    }

    public func setScale(percentX: Double, percentY: Double) {
        sprite.setScale(x: percentX, y: percentY)
    }

    public func setPosition(percentX: Double, percentY: Double) {
        sprite.setPosition(x: percentX, y: percentY)
    }

    public func translateTo(translation: TranslateTo) {
        sprite.translateTo(translation: translation)
    }

    public func setRotation(rotation: Double) {
        sprite.setRotation(rotation: rotation)
    }

    public func setDefaultScale(streamWidth: Int, streamHeight: Int) {
        let size = getObjectSize()
        sprite.setScale(x: Double(size.width) * 100 / Double(streamWidth), y: Double(size.height) * 100 / Double(streamHeight))
    }

    public func getScale() -> CGSize {
        return sprite.getScale()
    }

    public func getPosition() -> CGPoint {
        return sprite.getPosition()
    }

    public func getRotation() -> Double {
        return sprite.getRotation()
    }

    public func getObjectSize() -> CGSize {
        lock.lock()
        let size = objectImage?.extent.size ?? .zero
        lock.unlock()
        return size
    }

    open override func release() {
        setObject(image: nil)
        sprite.reset()
    }
}
