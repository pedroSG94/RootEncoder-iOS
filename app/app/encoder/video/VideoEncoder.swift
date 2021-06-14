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

extension UInt32 {
    func toBytes() -> [UInt8] {
        let b1 = UInt8(self & 0x1F)
        let b2 = UInt8(self >> 8)
        let b3 = UInt8(self >> 16)
        let b4 = UInt8(self >> 24)
        return [UInt8](arrayLiteral: b1, b2, b3, b4)
    }
}

public class VideoEncoder {
    
    private var width: Int32 = 640
    private var height: Int32 = 480
    private var fps: Int = 60
    private var bitrate: Int = 100 * 1000
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
            VTSessionSetProperties(sess, propertyDictionary: [
                kVTCompressionPropertyKey_ProfileLevel: kVTProfileLevel_H264_Baseline_AutoLevel,
                kVTCompressionPropertyKey_AverageBitRate: bitRate,
                kVTCompressionPropertyKey_MaxKeyFrameInterval: frameInterval,
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
        encoder.getValidRawBuffer(sampleBuffer: sampleBuffer)
    }
    
    //In iOS h264 is in AVC format and could contain multiple frames. So we need split frames and conver to annexb
    private func getValidRawBuffer(sampleBuffer: CMSampleBuffer) {
        let startCode = [UInt8](arrayLiteral: 0x00, 0x00, 0x00, 0x01)
        let keyFrame = isKeyFrame(sampleBuffer: sampleBuffer)
        
        if (keyFrame) {
            //write sps and pps
            guard let description = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }
            var parametersCount: Int = 0
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, parameterSetIndex: 0, parameterSetPointerOut: nil, parameterSetSizeOut: nil, parameterSetCountOut: &parametersCount, nalUnitHeaderLengthOut: nil)
            if (parametersCount != 2) { return }
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
        }
        
        let body = try! sampleBuffer.dataBuffer?.dataBytes()
        let bytes = [UInt8](body!)
        var offset = 0
        var unitLength: UInt32 = 0
        while (offset < bytes.count) {
            var lengthBytes = Array<UInt8>()
            lengthBytes.append(contentsOf: bytes[offset...(offset + 3)])
            unitLength = lengthBytes.withUnsafeBytes { $0.load(as: UInt32.self) }
            offset += 4
            //Big-Endian to Little-Endian
            unitLength = CFSwapInt32(unitLength)
            var rawH264 = Array<UInt8>()
            rawH264.append(contentsOf: startCode)
            rawH264.append(contentsOf: bytes[offset...(offset + Int(unitLength) - 1)])
            offset += Int(unitLength)
            var frame = Frame()
            frame.buffer = rawH264
            let end = Date().millisecondsSince1970
            let elapsedNanoSeconds = (end - initTs) * 1000
            frame.timeStamp = UInt64(elapsedNanoSeconds)
            frame.length = UInt32(frame.buffer!.count)
            
            callback.getH264Data(frame: frame)
        }
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
