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

public class MetalStreamInterface: NSObject, MetalInterface {
    
    public func getEncoderSize() -> CGSize {
        return CGSize(width: width, height: height)
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
    
    public func setForceFps(fps: Int) {
        fpsLimiter.setFps(fps: fps)
    }
    
    private var isPreviewHorizontalFlip = false
    private var isPreviewVerticalFlip = false
    private var isStreamHorizontalFlip = false
    private var isStreamVerticalFlip = false
    private var fpsLimiter = FpsLimiter()
    private var filtersQueue = SynchronizedQueue<Filter>(label: "filtersQueue", size: Int.max)
    private let blackFilter = CIFilter(name: "CIColorMatrix")
    private var callback: MetalViewCallback?
    private var muted = false
    private var width: CGFloat = 640
    private var height: CGFloat = 480
    private let aspectRatioMode = AspectRatioMode.ADJUST
    private var rotation = 0
    private var currentOrientation = 0
    private var rotated = false
    private let sensorManager = SensorManager()
    private weak var mtkView: MTKView? = nil
    private var previewImage: CIImage? = nil
    private var previewRotated = false
    private var previewOrientation: CGImagePropertyOrientation = .up
    private let mainRender = MainRender()

    public override init() {
        super.init()
        sensorManager.start(callback: { orientation in
            self.rotated = ((self.rotation == 0 || self.rotation == 180) && (orientation == 90 || orientation == 270)) ||
            ((self.rotation == 90 || self.rotation == 270) && (orientation == 0 || orientation == 180))
            self.currentOrientation = orientation
        })
    }

    public func setOrientation(orientation: Int) {
        self.rotation = orientation
        self.currentOrientation = orientation
        self.rotated = false
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
        guard var streamImage = mainRender.getImage(buffer: buffer) else { return }

        let orientation: CGImagePropertyOrientation = SizeCalculator.processMatrix(initialOrientation: rotation, currentOrientation: currentOrientation)

        while filtersQueue.itemsCount() > 0 {
            if let filter = filtersQueue.dequeue() {
                mainRender.setFilterAction(action: filter.filterAction, position: filter.position, baseFilterRender: filter.baseFilterRender)
            }
        }
        
        if mtkView != nil {
            var previewImage = streamImage
            mainRender.drawFilters(isPreview: true, image: &previewImage, orientation: orientation)
            let rotated = self.rotated
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let mtkView = self.mtkView else { return }
                self.previewImage = previewImage
                self.previewRotated = rotated
                self.previewOrientation = orientation
                mtkView.setNeedsDisplay()
            }
        }
        
        guard let callback = callback else { return }
        mainRender.drawFilters(isPreview: false, image: &streamImage, orientation: orientation)
        let rect = mainRender.drawEncoder(image: &streamImage, orientation: orientation, rotated: rotated, verticalFlip: isStreamVerticalFlip, horizontalFlip: isStreamHorizontalFlip)
        if muted {
            streamImage = muteImage(image: streamImage)
        }
        
        guard let pixelBuffer = mainRender.swapEncoderBuffer(image: streamImage, rect: rect) else { return }
        let pts = CMSampleBufferGetPresentationTimeStamp(buffer)
        callback.getVideoData(pixelBuffer: pixelBuffer, pts: pts)
    }

    public func addFilter(baseFilterRender: BaseFilterRender) {
        let _ = filtersQueue.enqueue(Filter(filterAction: FilterAction.ADD, position: 0, baseFilterRender: baseFilterRender))
    }

    public func addFilter(position: Int, baseFilterRender: BaseFilterRender) {
        let _ = filtersQueue.enqueue(Filter(filterAction: FilterAction.ADD_INDEX, position: position, baseFilterRender: baseFilterRender))
    }

    public func removeFilter(baseFilterRender: BaseFilterRender) {
        let _ = filtersQueue.enqueue(Filter(filterAction: FilterAction.REMOVE, position: 0, baseFilterRender: baseFilterRender))
    }
    
    public func removeFilter(position: Int) {
        let _ = filtersQueue.enqueue(Filter(filterAction: FilterAction.REMOVE_INDEX, position: position, baseFilterRender: NoFilterRender()))
    }

    public func clearFilters() {
        let _ = filtersQueue.enqueue(Filter(filterAction: FilterAction.CLEAR, position: 0, baseFilterRender: NoFilterRender()))
    }

    public func setFilter(baseFilterRender: BaseFilterRender) {
        let _ = filtersQueue.enqueue(Filter(filterAction: FilterAction.SET, position: 0, baseFilterRender: baseFilterRender))
    }

    public func setFilter(position: Int, baseFilterRender: BaseFilterRender) {
        let _ = filtersQueue.enqueue(Filter(filterAction: FilterAction.SET_INDEX, position: position, baseFilterRender: baseFilterRender))
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
        mainRender.initMetal(width: width, height: height)
    }
    
    public func attachPreview(mtkView: MTKView) {
        mtkView.autoResizeDrawable = true
        mtkView.framebufferOnly = false
        mtkView.device = mainRender.device
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = true
        mtkView.delegate = self
        self.mtkView = mtkView
    }

    public func deAttachPreview() {
        self.mtkView?.delegate = nil
        self.mtkView?.device = nil
        self.mtkView = nil
    }
}

extension MetalStreamInterface: MTKViewDelegate {

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

    }

    public func draw(in view: MTKView) {
        guard var previewImage = previewImage else { return }
        mainRender.drawPreview(previewImage: &previewImage, view: view, aspectRatioMode: aspectRatioMode, orientation: previewOrientation, rotated: previewRotated, verticalFlip: isPreviewVerticalFlip, horizontalFlip: isPreviewHorizontalFlip)
        mainRender.swapPreviewBuffer(view: view, image: previewImage)
    }
}

