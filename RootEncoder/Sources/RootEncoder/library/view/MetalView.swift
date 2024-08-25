//
//  MetalView.swift
//  RootEncoder
//
//  Created by Pedro  on 3/11/23.
//

import Foundation
import MetalKit
import CoreMedia

public class MetalView: MTKView, MetalInterface {
    public func muteVideo() {
        muted = true
    }
    
    public func unMuteVideo() {
        muted = false
    }
    
    public func isVideoMuted() -> Bool {
        return muted
    }
    
    public func setCallback(callback: MetalViewCallback?) {
        self.callback = callback
    }
    
    public func sendBuffer(buffer: CMSampleBuffer) {
        if Thread.isMainThread {
            self.buffer = buffer
            setNeedsDisplay()
        } else {
            DispatchQueue.main.async {
                self.sendBuffer(buffer: buffer)
            }
        }
    }
    
    public func addFilter(baseFilterRender: BaseFilterRender) {
        filters.append(baseFilterRender)
    }
    
    public func addFilter(position: Int, baseFilterRender: BaseFilterRender) {
        filters.insert(baseFilterRender, at: position)
        
    }
    
    public func removeFilter(position: Int) {
        filters.remove(at: position)
    }
    
    public func clearFilters() {
        filters.removeAll()
    }
    
    public func setFilter(baseFilterRender: BaseFilterRender) {
        setFilter(position: 0, baseFilterRender: baseFilterRender)
    }
    
    public func setFilter(position: Int, baseFilterRender: BaseFilterRender) {
        if filters.isEmpty && position == 0 {
            addFilter(baseFilterRender: baseFilterRender)
        } else {
            removeFilter(position: position)
            addFilter(position: position, baseFilterRender: baseFilterRender)
        }
    }
    
    public func setIsStreamHorizontalFlip(flip: Bool) {
        isStreamHorizontalFlip = flip
    }
    
    public func setIsStreamVerticalFlip(flip: Bool) {
        isStreamVerticalFlip = flip
    }
    
    public func setIsPreviewHorizontalFlip(flip: Bool) {
        isPreviewHorizontalFlip = flip
    }
    
    public func setIsPreviewVerticalFlip(flip: Bool) {
        isPreviewVerticalFlip = flip
    }
    
    private let blackFilter = CIFilter(name: "CIColorMatrix")
    private var muted = false
    private var isPreviewHorizontalFlip = false
    private var isPreviewVerticalFlip = false
    private var isStreamHorizontalFlip = false
    private var isStreamVerticalFlip = false
    private let aspectRatioMode = AspectRatioMode.ADJUST
    private var buffer: CMSampleBuffer? = nil
    private var context: CIContext? = nil
    private var width: CGFloat = 640
    private var height: CGFloat = 480
    private lazy var render: (any MTLCommandQueue)? = {
        return device?.makeCommandQueue()
    }()
    private let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    private let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
    private var callback: MetalViewCallback? = nil
    private var filters = [BaseFilterRender]()
    private let initialOrientation = UIDeviceOrientation(rawValue: CameraHelper.getOrientation().rawValue) ?? UIDeviceOrientation.landscapeLeft
    private var fpsLimiter = FpsLimiter()
    
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
    
    public func setForceFps(fps: Int) {
        fpsLimiter.setFps(fps: fps)
    }
    
    public func setEncoderSize(width: Int, height: Int) {
        self.width = CGFloat(width)
        self.height = CGFloat(height)
    }
}

extension MetalView: MTKViewDelegate {

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    public func draw(in view: MTKView) {
        if fpsLimiter.limitFps() {
            return
        }
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
            .cropToAspectRatio(aspectRatio: self.width / self.height)
            .scaleTo(width: self.width, height: self.height)

        let orientation: CGImagePropertyOrientation = SizeCalculator.processMatrix(initialOrientation: self.initialOrientation)
        
        //apply filters
        for filter in filters {
            streamImage = filter.draw(image: streamImage, orientation: orientation)
        }
        
        var w = streamImage.extent.width
        var h = streamImage.extent.height
        
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
        
        if muted {
            streamImage = muteImage(image: streamImage)
        }
        
        guard let callback = callback else { return }
        guard let pixelBuffer = toPixelBuffer(width: Int(rect.width), height: Int(rect.height)) else { return }
        
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
    
    private func muteImage(image: CIImage) -> CIImage {
        blackFilter?.setValue(image, forKey: kCIInputImageKey)
        blackFilter?.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        blackFilter?.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        blackFilter?.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        blackFilter?.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector") // Preserva el canal alfa

        return blackFilter?.outputImage ?? image
    }
}
