//
//  MetalInterface.swift
//  RootEncoder
//
//  Created by Pedro  on 5/4/24.
//

import Foundation
import CoreMedia

public protocol MetalInterface {
    
    func setOrientation(orientation: Int)
    
    func muteVideo()
    
    func unMuteVideo()
    
    func isVideoMuted() -> Bool
    
    func setEncoderSize(width: Int, height: Int)
        
    func setCallback(callback: MetalViewCallback?)
    
    func sendBuffer(buffer: CMSampleBuffer)
    
    /**
     * Replace the filter in position 0 or add the filter if list is empty.
     * You can modify filter's parameters after set it to stream.
     *
     * @param baseFilterRender filter to set.
     */
    func setFilter(baseFilterRender: BaseFilterRender)
    /**
     * Replaces the filter at the specified position with the specified filter.
     * You can modify filter's parameters after set it to stream.
     *
     * @param filterPosition filter position
     * @param baseFilterRender filter to set
     */
    func setFilter(position: Int, baseFilterRender: BaseFilterRender)
    /**
     * Appends the specified filter to the end.
     * You can modify filter's parameters after set it to stream.
     *
     * @param baseFilterRender filter to add
     */
    func addFilter(baseFilterRender: BaseFilterRender)
    /**
     * Inserts the specified filter at the specified position.
     * You can modify filter's parameters after set it to stream.
     *
     * @param filterPosition filter position
     * @param baseFilterRender filter to set
     */
    func addFilter(position: Int, baseFilterRender: BaseFilterRender)

    /**
     * Remove the filter at the specified position.
     *
     * @param filterPosition position of filter to remove
     */
    func removeFilter(position: Int)
    /**
     * Remove all filters
     */
    func clearFilters()
    /**
     * When true, flips only the stream horizontally
     */
    func setIsStreamHorizontalFlip(flip: Bool)
    /**
     * When true, flips only the stream vertically
     */
    func setIsStreamVerticalFlip(flip: Bool)

    /**
     * When true, flips only the preview horizontally
     */
    func setIsPreviewHorizontalFlip(flip: Bool)

    /**
     * When true, flips only the preview vertically
     */
    func setIsPreviewVerticalFlip(flip: Bool)
    
    func setForceFps(fps: Int)
}
