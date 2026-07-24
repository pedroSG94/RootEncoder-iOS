//
//  Created by Pedro  on 4/8/24.
//

import common
import Foundation
import CoreImage
import UIKit

public class ViewFilterRender: BaseObjectFilterRender {

    private var view: UIView? = nil
    private var render: Timer? = nil
    public var targetFps: Int = 30 {
        didSet {
            if targetFps < 1 { targetFps = 1 }
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.render != nil else { return }
                self.render?.invalidate()
                self.startRender()
            }
        }
    }

    public func setView(view: UIView?) {
        self.view = view
        stopRender()
        if view == nil {
            setObject(image: nil)
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.startRender()
        }
    }

    private func startRender() {
        updateSnapshot()
        render = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(targetFps), repeats: true) { [weak self] timer in
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
        setObject(image: ciImage)
    }

    public override func release() {
        stopRender()
        super.release()
    }
}
