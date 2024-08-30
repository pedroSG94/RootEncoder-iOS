//
//  File.swift
//  
//
//  Created by Pedro  on 30/8/24.
//

import Foundation
import CoreMedia
import CoreImage
import UIKit
import MetalKit

public class MetalStreamInterface: MetalInterface {
    
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
    
    public func setForceFps(fps: Int) {
        fpsLimiter.setFps(fps: fps)
    }
    
    private var isPreviewHorizontalFlip = false
    private var isPreviewVerticalFlip = false
    private var isStreamHorizontalFlip = false
    private var isStreamVerticalFlip = false
    private var fpsLimiter = FpsLimiter()
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var context: CIContext!
    private var textureCache: CVMetalTextureCache?
    private var filters = [BaseFilterRender]()
    private let blackFilter = CIFilter(name: "CIColorMatrix")
    private var callback: MetalViewCallback?
    private var muted = false
    private var width: CGFloat = 640
    private var height: CGFloat = 480
    private let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    private let aspectRatioMode = AspectRatioMode.ADJUST
    private var rotation = 0
    private var rotated = false
    private let sensorManager = SensorManager()
    private weak var mtkView: MTKView?
    
    public init() {
        self.device = MTLCreateSystemDefaultDevice()
        self.commandQueue = device.makeCommandQueue()
        self.context = CIContext(mtlDevice: device)
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        sensorManager.start(callback: { orientation in
            self.rotated = ((self.rotation == 0 || self.rotation == 180) && (orientation == 90 || orientation == 270)) ||
            ((self.rotation == 90 || self.rotation == 2700) && (orientation == 0 || orientation == 180))
        })
    }

    public func attachToMTKView(_ mtkView: MTKView) {
        self.mtkView = mtkView
        mtkView.device = self.device
        mtkView.framebufferOnly = false
    }
    
    public func setOrientation(orientation: Int) {
        self.rotation = orientation
    }
    
    public func setCallback(callback: MetalViewCallback?) {
        self.callback = callback
    }

    public func muteVideo() {
        muted = true
    }
    
    public func unMuteVideo() {
        muted = false
    }
    
    public func isVideoMuted() -> Bool {
        return muted
    }
    
    public func sendBuffer(buffer: CMSampleBuffer) {
        if fpsLimiter.limitFps() { return }
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }
        var streamImage = CIImage(cvPixelBuffer: imageBuffer)

        streamImage = streamImage.cropToAspectRatio(aspectRatio: width / height)
            .scaleTo(width: width, height: height)

        let orientation: CGImagePropertyOrientation = SizeCalculator.processMatrix(initialOrientation: rotation)
        
        // Apply filters
        for filter in filters {
            let orientation = SizeCalculator.processMatrix(initialOrientation: .landscapeLeft)
            streamImage = filter.draw(image: streamImage, orientation: orientation)
        }

        var w = streamImage.extent.width
        var h = streamImage.extent.height
                
        if (rotated) {
            w = streamImage.extent.height
            h = streamImage.extent.width
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

        /*
        if let mtkView = mtkView, let drawable = mtkView.currentDrawable {
            let renderCommandBuffer = commandQueue.makeCommandBuffer()!
            let bounds = CGRect(origin: .zero, size: mtkView.drawableSize)
            
            context.render(processedImage, to: drawable.texture, commandBuffer: renderCommandBuffer, bounds: bounds, colorSpace: colorSpace)
            renderCommandBuffer.present(drawable)
            renderCommandBuffer.commit()
        }
         */
        
        guard let pixelBuffer = toPixelBuffer(width: Int(rect.width), height: Int(rect.height)) else { return }
        context.render(streamImage, to: pixelBuffer)

        let pts = CMSampleBufferGetPresentationTimeStamp(buffer)
        callback?.getVideoData(pixelBuffer: pixelBuffer, pts: pts)
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

    private func toPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)

        guard status == kCVReturnSuccess else { return nil }
        return pixelBuffer
    }

    private func muteImage(image: CIImage) -> CIImage {
        blackFilter?.setValue(image, forKey: kCIInputImageKey)
        blackFilter?.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        blackFilter?.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        blackFilter?.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        blackFilter?.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector") // Preserves alpha channel

        return blackFilter?.outputImage ?? image
    }

    public func setEncoderSize(width: Int, height: Int) {
        self.width = CGFloat(width)
        self.height = CGFloat(height)
    }
}

