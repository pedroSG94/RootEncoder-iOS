//
//  MetalView.swift
//  RootEncoder
//
//  Created by Pedro  on 3/11/23.
//

import Foundation
import MetalKit
import CoreMedia
import encoder

public class MetalView: MTKView {
    
    private var buffer: CMSampleBuffer? = nil
    private var context: CIContext? = nil
    private lazy var render: (any MTLCommandQueue)? = {
        return device?.makeCommandQueue()
    }()
    private let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    private let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
    private var callback: MetalViewCallback? = nil
    private var filters = [BaseFilterRender]()
    
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
    
    public func setCallback(callback: MetalViewCallback?) {
        self.callback = callback
    }
    
    public func addFilter(filter: BaseFilterRender) {
        filters.append(filter)
    }
    
    public func removeFilter(position: Int) {
        filters.remove(at: position)
    }
    
    public func clearFilters() {
        filters.removeAll()
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
        //this image will be modified acording with filters
        var streamImage = CIImage(cvPixelBuffer: image)
        
        //apply filters
        for filter in filters {
            streamImage = filter.draw(image: streamImage)
        }
        
        //full screen mode
        let scaleX = drawableSize.width / streamImage.extent.width
        let scaleY = drawableSize.height / streamImage.extent.height
        
        let previewImage = streamImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let bounds = CGRect(origin: .zero, size: drawableSize)
        context.render(previewImage, to: currentDrawable.texture, commandBuffer: render, bounds: bounds, colorSpace: colorSpace)
        render.present(currentDrawable)
        render.commit()
        
        guard let callback = callback else { return }
        let pixelBuffer = toPixelBuffer(image: streamImage)
        context.render(_:streamImage, to: pixelBuffer!)
        let pts = CMSampleBufferGetPresentationTimeStamp(buffer!)
        callback.getVideoData(pixelBuffer: pixelBuffer!, pts: pts)
    }
    
    private func toPixelBuffer(image: CIImage) -> CVPixelBuffer? {
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.extent.width), Int(image.extent.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)

        guard (status == kCVReturnSuccess) else {
            return nil
        }

        return pixelBuffer
    }
}
