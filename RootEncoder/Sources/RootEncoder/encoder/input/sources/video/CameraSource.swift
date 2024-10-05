//
//  File.swift
//  RootEncoder
//
//  Created by Pedro  on 5/10/24.
//

import Foundation
import CoreMedia

public class CameraSource: VideoSource, GetCameraData {
    
    private lazy var camera: CameraManager = {
        CameraManager(callback: self)
    }()
    private var metalInterface: MetalInterface? = nil
    
    public init() { }
    
    public func create(width: Int, height: Int, fps: Int, rotation: Int) -> Bool {
        return camera.prepare(width: width, height: height, fps: fps, rotation: rotation)
    }
    
    public func start(metalInterface: MetalInterface) {
        self.metalInterface = metalInterface
        camera.start()
    }
    
    public func stop() {
        camera.stop()
    }
    
    public func isRunning() -> Bool {
        return camera.running
    }
    
    public func release() { }
    
    public func getYUVData(from buffer: CMSampleBuffer) {
        metalInterface?.sendBuffer(buffer: buffer)
    }
    
    public func switchCamera() {
        camera.switchCamera()
    }
    
    public func isLanternEnabled() -> Bool {
        camera.isTorchEnabled()
    }
    
    public func enabledLantern() {
        camera.setTorch(isOn: true)
    }
    
    public func disableLantern() {
        camera.setTorch(isOn: false)
    }
    
    public func setZoom(level: CGFloat) {
        camera.setZoom(level: level)
    }
    
    public func getZoom() -> CGFloat {
        return camera.getZoom()
    }
    
    public func getMaxZoom() -> CGFloat {
        return camera.getMaxZoom()
    }
    
    public func getMinZoom() -> CGFloat {
        return camera.getMinZoom()
    }
    
    public func getBackCameraResolutions() -> [CMVideoDimensions] {
        return camera.getBackCameraResolutions()
    }
    
    public func getFrontCameraResolutions() -> [CMVideoDimensions] {
        return camera.getBackCameraResolutions()
    }
}
