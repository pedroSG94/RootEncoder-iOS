//
//  MetalView.swift
//  RootEncoder
//
//  Created by Pedro  on 3/11/23.
//

import Common
import Encoder
import RTMP
import RTSP
import SRT
import Foundation
import MetalKit
import CoreMedia

public class MetalView: MTKView, MetalInterface {
    
    public func getEncoderSize() -> CGSize {
        return CGSize(width: width, height: height)
    }
    
    public func setOrientation(orientation: Int) {
        rotation = orientation
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
    private var width: CGFloat = 640
    private var height: CGFloat = 480
    private var rotation = 0
    private var callback: MetalViewCallback? = nil
    private var fpsLimiter = FpsLimiter()
    private var filtersQueue = SynchronizedQueue<Filter>(label: "filtersQueue", size: Int.max)
    private let mainRender = MainRender()
    
    public init() {
        super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())
        awakeFromNib()
    }
    
    public init(frame: CGRect) {
        super.init(frame: frame, device: MTLCreateSystemDefaultDevice())
        awakeFromNib()
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        if device == nil { device = MTLCreateSystemDefaultDevice() }
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
        mainRender.initMetal(width: width, height: height)
    }
}

extension MetalView: MTKViewDelegate {

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    public func draw(in view: MTKView) {
        if fpsLimiter.limitFps() { return }
        guard let buffer = buffer else { return }
        guard var streamImage = mainRender.getImage(buffer: buffer) else { return }
        
        let orientation: CGImagePropertyOrientation = SizeCalculator.processMatrix(initialOrientation: rotation)
        
        while filtersQueue.itemsCount() > 0 {
            if let filter = filtersQueue.dequeue() {
                mainRender.setFilterAction(action: filter.filterAction, position: filter.position, baseFilterRender: filter.baseFilterRender)
            }
        }
        
        var previewImage = streamImage
        let rotated = drawableSize.width > drawableSize.height && previewImage.extent.height > previewImage.extent.width
            || drawableSize.height > drawableSize.width && previewImage.extent.width > previewImage.extent.height
        mainRender.drawFilters(isPreview: true, image: &previewImage, orientation: orientation)
        mainRender.drawPreview(previewImage: &previewImage, view: view, aspectRatioMode: aspectRatioMode, orientation: orientation, rotated: rotated, verticalFlip: isPreviewVerticalFlip, horizontalFlip: isPreviewHorizontalFlip)
        mainRender.swapPreviewBuffer(view: view, image: previewImage)
        
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
    
    private func muteImage(image: CIImage) -> CIImage {
        blackFilter?.setValue(image, forKey: kCIInputImageKey)
        blackFilter?.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        blackFilter?.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        blackFilter?.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        blackFilter?.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector") // Preserva el canal alfa
        return blackFilter?.outputImage ?? image
    }
}
