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
    private var bitrate: Int = 1000 * 1000
    private var iFrameInterval: Int = 2
    private var initTs: Int64 = 0
    private var isSpsAndPpsSend = false
    private var running = false

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
        print("prepare video success")
        running = true
        return true
    }
    
    public func encodeFrame(buffer: CMSampleBuffer) {
        if (running) {
            guard let session: VTCompressionSession = session else { return }
            var flags: VTEncodeInfoFlags = []
            VTCompressionSessionEncodeFrame(session, imageBuffer: buffer.imageBuffer!, presentationTimeStamp: buffer.presentationTimeStamp, duration: buffer.duration, frameProperties: nil, sourceFrameRefcon: nil, infoFlagsOut: &flags)
        }
    }
    
    public func stop() {
        running = false
        guard let session: VTCompressionSession = session else { return }
        VTCompressionSessionInvalidate(session)
    }
    
    private var videoCallback: VTCompressionOutputCallback = {(outputCallbackRefCon: UnsafeMutableRawPointer?, _: UnsafeMutableRawPointer?, status: OSStatus, flags: VTEncodeInfoFlags, sampleBuffer: CMSampleBuffer?) in
        guard let sampleBuffer = sampleBuffer else { return }
        guard let refcon: UnsafeMutableRawPointer = outputCallbackRefCon else { return }
        if (status != noErr) {
            print("encoding failed")
            return
        }
        if (!CMSampleBufferDataIsReady(sampleBuffer)) {
            print("data is not ready")
            return
        }
        
        if (flags == VTEncodeInfoFlags.frameDropped) {
            print("frame dropped")
            return
        }

        let encoder: VideoEncoder = Unmanaged<VideoEncoder>.fromOpaque(refcon).takeUnretainedValue()
        var frame = Frame()
        let keyFrame = encoder.isKeyFrame(sampleBuffer: sampleBuffer)
        let data = encoder.getValidRawBuffer(sampleBuffer: sampleBuffer)
        guard let buffer: Array<UInt8> = data else { return }
        frame.buffer = buffer
        let end = Date().millisecondsSince1970
        let elapsedNanoSeconds = (end - encoder.initTs) * 1000000
        frame.timeStamp = UInt64(elapsedNanoSeconds)
        frame.length = UInt32(frame.buffer!.count)
        frame.flag = keyFrame ? 5 : 1
        encoder.callback.getH264Data(frame: frame)
    }
    
    //In iOS only h264 body is provided. So we need add header information in buffers
    private func getValidRawBuffer(sampleBuffer: CMSampleBuffer) -> [UInt8]? {
        let startCode = [UInt8](arrayLiteral: 0x00, 0x00, 0x00, 0x01)
        let keyFrame = isKeyFrame(sampleBuffer: sampleBuffer)
        var rawH264 = Array<UInt8>()
        var idrSlice: UInt8 = 65
        rawH264.append(contentsOf: startCode)
        if (keyFrame) {
            //write sps and pps
            guard let description = CMSampleBufferGetFormatDescription(sampleBuffer) else { return nil }
            var parametersCount: Int = 0
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, parameterSetIndex: 0, parameterSetPointerOut: nil, parameterSetSizeOut: nil, parameterSetCountOut: &parametersCount, nalUnitHeaderLengthOut: nil)
            if (parametersCount != 2) { return nil }
            var sps: UnsafePointer<UInt8>?
            var spsSize: Int = 0
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, parameterSetIndex: 0, parameterSetPointerOut: &sps, parameterSetSizeOut: &spsSize, parameterSetCountOut: nil, nalUnitHeaderLengthOut: nil)
            var pps: UnsafePointer<UInt8>?
            var ppsSize: Int = 0
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, parameterSetIndex: 1, parameterSetPointerOut: &pps, parameterSetSizeOut: &ppsSize, parameterSetCountOut: nil, nalUnitHeaderLengthOut: nil)
            
            var spsData = Array<UInt8>()
            for i in 0...spsSize - 1 {
                spsData.append(sps![i])
            }
            var ppsData = Array<UInt8>()
            for i in 0...ppsSize - 1 {
                ppsData.append(pps![i])
            }
            
            if (!isSpsAndPpsSend) {
                callback.getSpsAndPps(sps: spsData, pps: ppsData)
                isSpsAndPpsSend = true
            }
            rawH264.append(contentsOf: spsData)
            rawH264.append(contentsOf: startCode)
            rawH264.append(contentsOf: ppsData)
            rawH264.append(contentsOf: startCode)
            idrSlice = 101
        }
        rawH264.append(idrSlice)
        let body = try! sampleBuffer.dataBuffer?.dataBytes()
        let bytes = [UInt8](body!)
        rawH264.append(contentsOf: bytes)
        return rawH264
    }
    
    private func isKeyFrame(sampleBuffer: CMSampleBuffer) -> Bool {
        guard
            let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[CFString: Any]],
            let value = attachments.first?[kCMSampleAttachmentKey_NotSync] as? Bool else {
            return true
        }
        return !value
    }
}
