//
//  VideoEncoder.swift
//  app
//
//  Created by Pedro  on 16/5/21.
//  Copyright © 2021 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation
import VideoToolbox
import CoreFoundation

extension OSStatus {
    var error: NSError? {
        guard self != noErr else { return nil }
        
        let message = SecCopyErrorMessageString(self, nil) as String? ?? "Unknown error"
        return NSError(domain: NSOSStatusErrorDomain, code: Int(self), userInfo: [NSLocalizedDescriptionKey: message])
    }
}

public class VideoEncoder {
    
    private var width: Int = 1920
    private var height: Int = 1080
    private var fps: Int = 30
    private var bitrate: Int = 3000 * 1000
    private var iFrameInterval: Int = 2
    private var initTs: Int64 = 0

    private var session: VTCompressionSession?
    private let callback: GetH264Data
    
    
    private var attributes: [NSString: AnyObject] {
        var attributes: [NSString: AnyObject] = [
            kCVPixelBufferIOSurfacePropertiesKey: [:] as AnyObject,
            kCVPixelBufferOpenGLESCompatibilityKey: kCFBooleanTrue
        ]
        attributes[kCVPixelBufferWidthKey] = NSNumber(value: width)
        attributes[kCVPixelBufferHeightKey] = NSNumber(value: height)
        return attributes
    }
    
    private var properties: [NSString: NSObject] {
        let properties: [NSString: NSObject] = [
            kVTCompressionPropertyKey_RealTime: kCFBooleanTrue,
            kVTCompressionPropertyKey_AverageBitRate: Int(bitrate) as NSObject,
            kVTCompressionPropertyKey_ExpectedFrameRate: NSNumber(value: fps),
            kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration: NSNumber(value: iFrameInterval),
        ]
        return properties
    }
    
    public init(callback: GetH264Data) {
        self.callback = callback
    }
    
    public func prepareVideo() -> Bool {
        let result = VTCompressionSessionCreate(allocator: kCFAllocatorDefault, width: Int32(width), height: Int32(height), codecType: kCMVideoCodecType_H264, encoderSpecification: nil, imageBufferAttributes: attributes as CFDictionary?, compressedDataAllocator: nil, outputCallback: videoCallback, refcon: Unmanaged.passUnretained(self).toOpaque(), compressionSessionOut: &session
        )
        if (result != noErr) {
            print("fail to create encoder")
            return false
        }
        let pro = VTSessionSetProperties(session!, propertyDictionary: properties as CFDictionary)
        if (pro != noErr) {
            print("fail to set properties encoder")
            return false
        }
        let prepare = VTCompressionSessionPrepareToEncodeFrames(session!)
        if (prepare != noErr) {
            print("fail to prepare encoder")
            return false
        }
        self.initTs = Date().millisecondsSince1970
        print("prepare success")
        return true
    }
    
    public func encodeFrame(buffer: CMSampleBuffer) {
        guard let session: VTCompressionSession = session else { return }
        var flags: VTEncodeInfoFlags = []
        VTCompressionSessionEncodeFrame(session, imageBuffer: buffer.imageBuffer!, presentationTimeStamp: buffer.presentationTimeStamp, duration: buffer.duration, frameProperties: nil, sourceFrameRefcon: nil, infoFlagsOut: &flags)
        print("flag: \(flags.rawValue)")
    }
    
    private var videoCallback: VTCompressionOutputCallback = {(outputCallbackRefCon: UnsafeMutableRawPointer?, _: UnsafeMutableRawPointer?, status: OSStatus, _: VTEncodeInfoFlags, sampleBuffer: CMSampleBuffer?) in
        guard
            let refcon: UnsafeMutableRawPointer = outputCallbackRefCon,
            let sampleBuffer: CMSampleBuffer = sampleBuffer, status == noErr else {
                if status == kVTParameterErr {
                    // on iphone 11 with size=1792x827 this occurs
                }
            return
        }
        let data = try! sampleBuffer.dataBuffer?.dataBytes()
        let bytes = [UInt8](data!)
        let encoder: VideoEncoder = Unmanaged<VideoEncoder>.fromOpaque(refcon).takeUnretainedValue()
        let end = Date().millisecondsSince1970
        let elapsedNanoSeconds = (end - encoder.initTs) * 1000000
        var frame = Frame()
        frame.buffer = bytes
        frame.timeStamp = UInt64(elapsedNanoSeconds)
        frame.length = UInt32(bytes.count)
        encoder.callback.getH264Data(frame: frame)
    }
    
    private func bufferToUInt(imageBuffer: CVImageBuffer) -> [UInt8] {
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let byterPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let srcBuff = CVPixelBufferGetBaseAddress(imageBuffer)

        let data = NSData(bytes: srcBuff, length: byterPerRow * height)
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))

        return [UInt8].init(repeating: 0, count: data.length / MemoryLayout<UInt8>.size)
    }
}
