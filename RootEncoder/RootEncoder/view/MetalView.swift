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
    
    private var isPreviewHorizontalFlip = false
    private var isPreviewVerticalFlip = false
    private var isStreamHorizontalFlip = false
    private var isStreamVerticalFlip = false
    private let aspectRatioMode = AspectRatioMode.ADJUST
    private var buffer: CMSampleBuffer? = nil
    private var context: CIContext? = nil
    private lazy var render: (any MTLCommandQueue)? = {
        return device?.makeCommandQueue()
    }()
    private let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    private let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
    private var callback: MetalViewCallback? = nil
    private var filters = [BaseFilterRender]()
    private let initialOrientation = UIDevice.current.orientation
    
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
        guard let buffer = buffer else { return }
        guard let image = buffer.imageBuffer else {
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
        
        var w = streamImage.extent.width
        var h = streamImage.extent.height
        let orientation: CGImagePropertyOrientation = SizeCalculator.processMatrix(initialOrientation: self.initialOrientation)
        
        let rotated = drawableSize.width > drawableSize.height && h > w 
            || drawableSize.height > drawableSize.width && w > h
        
        if (rotated) {
            w = streamImage.extent.height
            h = streamImage.extent.width
        }
        
        let viewport = SizeCalculator.getViewPort(mode: aspectRatioMode, streamWidth: w, streamHeight: h, previewWidth: drawableSize.width, previewHeight: drawableSize.height)
        
        var previewImage = streamImage
            .oriented(orientation)
            .transformed(by: CGAffineTransform(scaleX: viewport.scaleX, y: viewport.scaleY))
            .transformed(by: CGAffineTransform(translationX: viewport.positionX, y: viewport.positionY))
            
        if (isPreviewVerticalFlip) {
            previewImage = previewImage
                .transformed(by: CGAffineTransform(scaleX: 1, y: -1))
                .transformed(by: CGAffineTransform(translationX: 0, y: drawableSize.height))
        }
        if (isPreviewHorizontalFlip) {
            previewImage = previewImage
                .transformed(by: CGAffineTransform(scaleX: -1, y: 1))
                .transformed(by: CGAffineTransform(translationX: drawableSize.width, y: 0))
        }
        if (isStreamVerticalFlip) {
            streamImage = streamImage
                .transformed(by: CGAffineTransform(scaleX: 1, y: -1))
                .transformed(by: CGAffineTransform(translationX: 0, y: streamImage.extent.height))
        }
        if (isStreamHorizontalFlip) {
            streamImage = streamImage
                .transformed(by: CGAffineTransform(scaleX: -1, y: 1))
                .transformed(by: CGAffineTransform(translationX: streamImage.extent.width, y: 0))
        }
        
        let bounds = CGRect(origin: .zero, size: drawableSize)
        context.render(previewImage, to: currentDrawable.texture, commandBuffer: render, bounds: bounds, colorSpace: colorSpace)
        render.present(currentDrawable)
        render.commit()
        
        var rect = CGRect(x: 0, y: 0, width: streamImage.extent.width, height: streamImage.extent.height)
        
        if (rotated) {
            //TODO offset to center image
            if (streamImage.extent.height > streamImage.extent.width) { //portrait
                let factor = streamImage.extent.width / streamImage.extent.height
                let scaledHeight = streamImage.extent.width * factor
                let scaleY = scaledHeight / streamImage.extent.height
                let offset = (streamImage.extent.height - scaledHeight) / 2

                streamImage = streamImage.oriented(orientation)
                    .transformed(by: CGAffineTransform(scaleX: 1, y: 1 - scaleY))
                    .transformed(by: CGAffineTransform(translationX: 0, y: offset * scaleY))
                rect = CGRect(x: 0, y: 0, width: streamImage.extent.width, height: scaledHeight)
            } else { //landscape
                let factor = streamImage.extent.height / streamImage.extent.width
                let scaledWidth = streamImage.extent.height * factor
                let scaleX = scaledWidth / streamImage.extent.width
                let offset = (streamImage.extent.width - scaledWidth) / 2
                
                streamImage = streamImage.oriented(orientation)
                    .transformed(by: CGAffineTransform(scaleX: 1 - scaleX, y: 1))
                    .transformed(by: CGAffineTransform(translationX: offset * scaleX, y: 0))
                rect = CGRect(x: 0, y: 0, width: scaledWidth, height: streamImage.extent.height)
            }
            
        }
        
        guard let callback = callback else { return }
        guard let pixelBuffer = toPixelBuffer(width: Int(rect.width), height: Int(rect.height)) else { return }
        
//        context.render(_:streamImage, to: pixelBuffer, bounds: rect, colorSpace: colorSpace)
        context.render(_:streamImage, to: pixelBuffer)

        let pts = CMSampleBufferGetPresentationTimeStamp(buffer)
        callback.getVideoData(pixelBuffer: pixelBuffer, pts: pts)
    }
    
    private func toPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)

        guard (status == kCVReturnSuccess) else {
            return nil
        }

        return pixelBuffer
    }
}
