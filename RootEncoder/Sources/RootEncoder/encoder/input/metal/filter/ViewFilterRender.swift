//
//  Created by Pedro  on 4/8/24.
//

import Foundation
import CoreImage
import SwiftUI

public class ViewFilterRender: BaseFilterRender {

    private var view: UIView? = nil
    private let sprite = Sprite()
    private let lock = NSLock()
    private var snapshot: CIImage? = nil
    private let fps: Double = 30
    private var render: Timer? = nil

    public override func draw(image: CIImage, orientation: CGImagePropertyOrientation, isPreview: Bool) -> CIImage {
        lock.lock()
        let filterView = snapshot
        lock.unlock()
        guard let filterView = filterView else { return image }

        let scale = sprite.getCalculatedScale(image: image.extent, filter: filterView.extent)
        let position = sprite.getCalculatedPosition(image: image.extent, filter: filterView.extent)
        let rotation = sprite.getCalculatedRotation()

        let scaled = filterView
            .transformed(by: CGAffineTransform(scaleX: scale.width, y: scale.height))
            .transformed(by: CGAffineTransform(rotationAngle: rotation))
            .transformed(by: CGAffineTransform(translationX: position.width, y: position.height))
        return scaled.composited(over: image)
    }
    
    public func setView(view: UIView?) {
        self.view = view
        stopRender()
        if view == nil { return }
        DispatchQueue.main.async { [weak self] in
            self?.startRender()
        }
    }

    private func startRender() {
        updateSnapshot()
        render = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { [weak self] timer in
            self?.updateSnapshot()
        }
    }
    
    private func stopRender() {
        DispatchQueue.main.async { [weak self] in
            self?.render?.invalidate()
            self?.render = nil
        }
    }

    private func updateSnapshot() {
        guard let view = view else { return }
        let bounds = view.bounds
        if bounds.width <= 0 || bounds.height <= 0 { return }
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let image = renderer.image { _ in
            view.drawHierarchy(in: bounds, afterScreenUpdates: false)
        }
        guard let ciImage = CIImage(image: image) else { return }
        lock.lock()
        snapshot = ciImage
        lock.unlock()
    }
    
    public override func release() {
        stopRender()
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
}
