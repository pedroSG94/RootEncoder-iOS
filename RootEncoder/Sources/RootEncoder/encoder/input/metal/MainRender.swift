//
//  MainRender.swift
//  RootEncoder
//
//  Created by Pedro  on 09/07/2026.
//
import Foundation
import CoreMedia
import CoreImage
import UIKit
import MetalKit

public class MainRender {
    
    private let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let context: CIContext
    private var width = 0
    private var height = 0
    
    init() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = device.makeCommandQueue()!
        self.context = CIContext(mtlCommandQueue: commandQueue)
    }
    
    public func initMetal(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
    
    private var filterRenders = [BaseFilterRender]()
    
    private func setFilter(position: Int, baseFilterRender: BaseFilterRender) {
        baseFilterRender.setMetalInfo(commandQueue: commandQueue, context: context)
        baseFilterRender.initMetal(device: device)
        if filterRenders.isEmpty && position == 0 {
            addFilter(baseFilterRender: baseFilterRender)
        } else {
            removeFilter(position: position)
            addFilter(position: position, baseFilterRender: baseFilterRender)
        }
    }
    
    private func addFilter(baseFilterRender: BaseFilterRender) {
        baseFilterRender.setMetalInfo(commandQueue: commandQueue, context: context)
        baseFilterRender.initMetal(device: device)
        filterRenders.append(baseFilterRender)
    }
    
    private func addFilter(position: Int, baseFilterRender: BaseFilterRender) {
        baseFilterRender.setMetalInfo(commandQueue: commandQueue, context: context)
        baseFilterRender.initMetal(device: device)
        filterRenders.insert(baseFilterRender, at: position)
    }
    
    private func removeFilter(baseFilterRender: BaseFilterRender) {
        filterRenders.removeAll { ($0 as AnyObject) === (baseFilterRender as AnyObject) }
        baseFilterRender.release()
    }
    
    private func removeFilter(position: Int) {
        let filter = filterRenders.remove(at: position)
        filter.release()
    }
    
    private func clearFilters() {
        filterRenders.forEach { filter in filter.release() }
        filterRenders.removeAll()
    }
    
    func setFilterAction(action: FilterAction, position: Int, baseFilterRender: BaseFilterRender) {
        switch (action) {
        case .SET:
            if filterRenders.count > 0 {
                setFilter(position: position, baseFilterRender: baseFilterRender)
            } else {
                addFilter(baseFilterRender: baseFilterRender)
            }
        case .SET_INDEX:
            setFilter(position: position, baseFilterRender: baseFilterRender)
        case .ADD:
            addFilter(baseFilterRender: baseFilterRender)
        case .ADD_INDEX:
            addFilter(position: position, baseFilterRender: baseFilterRender)
        case .CLEAR:
            clearFilters()
        case .REMOVE:
            removeFilter(baseFilterRender: baseFilterRender)
        case .REMOVE_INDEX:
            removeFilter(position: position)
        }
    }
    
    func filtersCount() -> Int {
        return filterRenders.count
    }
    
    func drawFilters(isPreview: Bool, image: inout CIImage, orientation: CGImagePropertyOrientation) {
        let validFilters = filterRenders.filter {
            if isPreview { $0.renderMode != .OUTPUT } else { $0.renderMode != .PREVIEW }
        }
        if validFilters.isEmpty { return }
        var filteredImage = image.oriented(orientation)
        validFilters.forEach { filter in
            filteredImage = filter.draw(image: filteredImage, orientation: orientation, isPreview: isPreview)
        }
        image = filteredImage.oriented(inverseOrientation(orientation))
    }

    private func inverseOrientation(_ orientation: CGImagePropertyOrientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .left:
            return .right
        case .right:
            return .left
        default:
            return orientation
        }
    }
    
    func drawPreview(previewImage: inout CIImage, view: MTKView, aspectRatioMode: AspectRatioMode, orientation: CGImagePropertyOrientation, rotated: Bool, verticalFlip: Bool, horizontalFlip: Bool) {
        var w = previewImage.extent.width
        var h = previewImage.extent.height

        if (rotated) {
            w = previewImage.extent.height
            h = previewImage.extent.width
        }
        let previewWidth = view.drawableSize.width
        let previewHeight = view.drawableSize.height
        let viewport = SizeCalculator.getViewPort(mode: aspectRatioMode, streamWidth: w, streamHeight: h, previewWidth: previewWidth, previewHeight: previewHeight)

        previewImage = previewImage
            .oriented(orientation)
            .transformed(by: CGAffineTransform(scaleX: viewport.scaleX, y: viewport.scaleY))
            .transformed(by: CGAffineTransform(translationX: viewport.positionX, y: viewport.positionY))

        if (verticalFlip) {
            previewImage = previewImage
                .transformed(by: CGAffineTransform(scaleX: 1, y: -1))
                .transformed(by: CGAffineTransform(translationX: 0, y: previewHeight))
        }
        if (horizontalFlip) {
            previewImage = previewImage
                .transformed(by: CGAffineTransform(scaleX: -1, y: 1))
                .transformed(by: CGAffineTransform(translationX: previewWidth, y: 0))
        }
    }
    
    func drawEncoder(image: inout CIImage, orientation: CGImagePropertyOrientation, rotated: Bool, verticalFlip: Bool, horizontalFlip: Bool) -> CGRect {
        if (verticalFlip) {
            image = image
                .transformed(by: CGAffineTransform(scaleX: 1, y: -1))
                .transformed(by: CGAffineTransform(translationX: 0, y: image.extent.height))
        }
        if (horizontalFlip) {
            image = image
                .transformed(by: CGAffineTransform(scaleX: -1, y: 1))
                .transformed(by: CGAffineTransform(translationX: image.extent.width, y: 0))
        }
        
        var rect = CGRect(x: 0, y: 0, width: image.extent.width, height: image.extent.height)
        
        if (rotated) {
            if (image.extent.height > image.extent.width) { //portrait
                let factor = image.extent.width / image.extent.height
                let scaledHeight = image.extent.width * factor
                let scaleY = scaledHeight / image.extent.height
                let offset = (image.extent.height - scaledHeight) / 2

                image = image.oriented(orientation)
                    .transformed(by: CGAffineTransform(scaleX: 1, y: 1 - scaleY))
                    .transformed(by: CGAffineTransform(translationX: 0, y: offset * scaleY))
                rect = CGRect(x: 0, y: 0, width: image.extent.width, height: scaledHeight)
            } else { //landscape
                let factor = image.extent.height / image.extent.width
                let scaledWidth = image.extent.height * factor
                let scaleX = scaledWidth / image.extent.width
                let offset = (image.extent.width - scaledWidth) / 2
                
                image = image.oriented(orientation)
                    .transformed(by: CGAffineTransform(scaleX: 1 - scaleX, y: 1))
                    .transformed(by: CGAffineTransform(translationX: offset * scaleX, y: 0))
                rect = CGRect(x: 0, y: 0, width: scaledWidth, height: image.extent.height)
            }
        } else {
            image = image.oriented(orientation)
        }
        return rect
    }
    
    func swapEncoderBuffer(image: CIImage, rect: CGRect) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(rect.width), Int(rect.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        context.render(image, to: buffer)
        return buffer
    }
    
    func getImage(buffer: CMSampleBuffer) -> CIImage? {
        let width = CGFloat(width)
        let height = CGFloat(height)
        guard let imageBuffer = CMSampleBufferGetImageBuffer(buffer) else { return nil }
        return CIImage(cvPixelBuffer: imageBuffer).cropToAspectRatio(aspectRatio: width / height)
            .scaleTo(width: width, height: height)
    }
    
    func swapPreviewBuffer(view: MTKView, image: CIImage) {
        guard let drawable = view.currentDrawable, let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        let rect = CGRect(origin: .zero, size: view.drawableSize)
        context.render(image, to: drawable.texture, commandBuffer: commandBuffer, bounds: rect, colorSpace: colorSpace)
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
