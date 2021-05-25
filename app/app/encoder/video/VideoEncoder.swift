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

public class VideoEncoder {
    
    private var width: Int32 = 640
    private var height: Int32 = 480
    private var fps: Int = 30
    private var bitrate: Int = 1200 * 1000
    private var iFrameInterval: Int = 2
    private var initTs: Int64 = 0
    private var isSpsAndPpsSend = false
    private var running = false

    private var session: VTCompressionSession?
    private let callback: GetH264Data
    
    public init(callback: GetH264Data) {
        self.callback = callback
    }
    
    public func prepareVideo() -> Bool {
        let err = VTCompressionSessionCreate(allocator: nil, width: width, height: height, codecType: kCMVideoCodecType_H264, encoderSpecification: nil, imageBufferAttributes: nil, compressedDataAllocator: nil, outputCallback: videoCallback, refcon: Unmanaged.passUnretained(self).toOpaque(), compressionSessionOut: &session)
        
        if err == errSecSuccess{
            guard let sess = self.session else { return false }
            let bitRate = self.bitrate
            let frameInterval: Int32 = 60
            let limti = [Double(bitRate) * 1.5 / 8, 1]
            VTSessionSetProperties(sess, propertyDictionary: [
                kVTCompressionPropertyKey_ProfileLevel: kVTProfileLevel_H264_Baseline_AutoLevel,
                kVTCompressionPropertyKey_AverageBitRate: bitRate,
                kVTCompressionPropertyKey_MaxKeyFrameInterval: frameInterval,
                kVTCompressionPropertyKey_DataRateLimits: limti,
                kVTCompressionPropertyKey_RealTime: true,
                kVTCompressionPropertyKey_Quality: 0.25,
            ] as CFDictionary)
            VTCompressionSessionPrepareToEncodeFrames(sess)
            self.initTs = Date().millisecondsSince1970
            print("prepare video success")
            running = true
            return true
        }else{
            return false
        }
    }
    
    public func encodeFrame(buffer: CMSampleBuffer) {
        if (running) {
            guard let session = self.session else { return }
            guard let px = CMSampleBufferGetImageBuffer(buffer) else { return }
            let time = CMSampleBufferGetPresentationTimeStamp(buffer)

            var flag:VTEncodeInfoFlags = VTEncodeInfoFlags()
            VTCompressionSessionEncodeFrame(session, imageBuffer: px, presentationTimeStamp: time, duration: time, frameProperties: nil, sourceFrameRefcon: nil, infoFlagsOut: &flag)
        }
    }
    
    public func stop() {
        running = false
        guard let session: VTCompressionSession = session else { return }
        VTCompressionSessionInvalidate(session)
    }
    
    private var videoCallback: VTCompressionOutputCallback = {(outputCallbackRefCon: UnsafeMutableRawPointer?, _: UnsafeMutableRawPointer?, status: OSStatus, flags: VTEncodeInfoFlags, sampleBuffer: CMSampleBuffer?) in
        guard let sampleBuffer = sampleBuffer else {
            print("nil bufer")
            return
        }
        guard let refcon: UnsafeMutableRawPointer = outputCallbackRefCon else {
            print("nil pointer")
            return
        }
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
        let elapsedNanoSeconds = (end - encoder.initTs) * 1000
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
