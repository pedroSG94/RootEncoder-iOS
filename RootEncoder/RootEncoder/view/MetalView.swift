//
//  MetalView.swift
//  RootEncoder
//
//  Created by Pedro  on 3/11/23.
//

import Foundation
import MetalKit
import CoreMedia

public class MetalView: MTKView {
    
    private var buffer: CMSampleBuffer? = nil
    private var context: CIContext? = nil
    private lazy var render: (any MTLCommandQueue)? = {
        return device?.makeCommandQueue()
    }()
    private let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    
    public init() {
        super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())
        awakeFromNib()
        context = CIContext(mtlDevice: device!)
    }
    
    public init(frame: CGRect) {
        super.init(frame: frame, device: MTLCreateSystemDefaultDevice())
        awakeFromNib()
        context = CIContext(mtlDevice: device!)
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        self.device = MTLCreateSystemDefaultDevice()
        context = CIContext(mtlDevice: device!)
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        delegate = self
        framebufferOnly = false
        enableSetNeedsDisplay = true
    }
    
    public func update(buffer: CMSampleBuffer) {
        if Thread.isMainThread {
            self.buffer = buffer
            setNeedsDisplay()
        } else {
            DispatchQueue.main.async {
                self.update(buffer: buffer)
            }
        }
    }
}

extension MetalView: MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    public func draw(in view: MTKView) {
        guard 
            let currentDrawable = currentDrawable,
            let context = context,
            let render = self.render?.makeCommandBuffer() else {
                return
            }
        guard let image = self.buffer?.imageBuffer else {
            render.present(currentDrawable)
            render.commit()
            return
        }
        var displayImage = CIImage(cvPixelBuffer: image)
        let bounds = CGRect(origin: .zero, size: drawableSize)
        
        //full screen mode
        let scaleX = drawableSize.width / displayImage.extent.width
        let scaleY = drawableSize.height / displayImage.extent.height
        
        displayImage = displayImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        context.render(displayImage, to: currentDrawable.texture, commandBuffer: render, bounds: bounds, colorSpace: colorSpace)
        render.present(currentDrawable)
        render.commit()
    }
}
