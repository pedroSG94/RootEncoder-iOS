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
    
    private(set) var width = 640
    private(set) var height = 480
    private(set) var fps: Int = 30
    private var bitrate: Int = 1500 * 1000
    private var iFrameInterval: Int = 2
    private var initTs: Int64 = 0
    private var isSpsAndPpsSend = false
    private var running = false
    private var forceKey = false
    private(set) var rotation = 0
    private var codec = CodecUtil.H264
    private let thread = DispatchQueue(label: "VideoEncoder")
    private let threadOutput = DispatchQueue(label: "VideoEncoderOutput")
    private let syncQueue = SynchronizedQueue<VideoFrame>(label: "VideoEncodeQueue", size: 60)

    private var session: VTCompressionSession? = nil
    private let callback: GetVideoData
    
    public init(callback: GetVideoData) {
        self.callback = callback
    }

    public func prepareVideo() -> Bool {
        prepareVideo(width: width, height: height, fps: fps, bitrate: bitrate, iFrameInterval: iFrameInterval, rotation: rotation)
    }
    
    public func prepareVideo(width: Int, height: Int, fps: Int, bitrate: Int, iFrameInterval: Int, rotation: Int) -> Bool {
        let w = if (rotation == 90 || rotation == 270) {
            height
        } else  {
            width
        }
        let h = if (rotation == 90 || rotation == 270) {
            width
        } else  {
            height
        }
        let err = VTCompressionSessionCreate(allocator: nil, width: Int32(w), height: Int32(h),
                codecType: codec.value, encoderSpecification: nil, imageBufferAttributes: nil,
                compressedDataAllocator: nil, outputCallback: videoCallback, refcon: Unmanaged.passUnretained(self).toOpaque(),
                compressionSessionOut: &session)
        self.width = width
        self.height = height
        self.fps = fps
        self.bitrate = bitrate
        self.iFrameInterval = iFrameInterval
        if err == errSecSuccess{
            guard let sess = session else { return false }
            let frameInterval: Int32 = 60
            let bitrateMode = if #available(iOS 16.0, *) {
                kVTCompressionPropertyKey_ConstantBitRate
            } else {
                kVTCompressionPropertyKey_AverageBitRate
            }
            VTSessionSetProperties(sess, propertyDictionary: [
                bitrateMode: bitrate,
                kVTCompressionPropertyKey_ProfileLevel: codec.profile,
                kVTCompressionPropertyKey_ExpectedFrameRate: fps,
                kVTCompressionPropertyKey_MaxKeyFrameInterval: frameInterval,
                kVTCompressionPropertyKey_RealTime: true,
                kVTCompressionPropertyKey_AllowFrameReordering: true
            ] as CFDictionary)
            VTCompressionSessionPrepareToEncodeFrames(sess)
            print("prepare video success")
            return true
        }else{
            return false
        }
    }
    
    public func start() {
        initTs = Date().millisecondsSince1970
        running = true
        syncQueue.clear()
        thread.async {
            while (self.running) {
                let buffer = self.syncQueue.dequeue()
                if let buffer = buffer {
                    guard let session = self.session else { return }
                    var properties: Dictionary<String, Any>?
                    if (self.forceKey) {
                        self.forceKey = false
                        properties = [
                            kVTEncodeFrameOptionKey_ForceKeyFrame as String: true
                        ];
                    }
                    var flag:VTEncodeInfoFlags = VTEncodeInfoFlags()
                    VTCompressionSessionEncodeFrame(session, imageBuffer: buffer.pixelBuffer, presentationTimeStamp: buffer.pts, duration: buffer.pts, frameProperties: properties as CFDictionary?, sourceFrameRefcon: nil, infoFlagsOut: &flag)
                }
            }
        }
    }
    
    public func setCodec(codec: VideoCodec) {
        switch codec {
        case .H264:
            self.codec = CodecUtil.H264
        case .H265:
            self.codec = CodecUtil.H265
        }
    }

    public func forceKeyFrame() {
        forceKey = true
    }

    public func encodeFrame(buffer: CMSampleBuffer) {
        if (running) {
            guard let px = CMSampleBufferGetImageBuffer(buffer) else { return }
            let time = CMSampleBufferGetPresentationTimeStamp(buffer)
            let frame = VideoFrame(pixelBuffer: px, pts: time)
            let _ = syncQueue.enqueue(frame)
        }
    }
    
    public func encodeFrame(pixelBuffer: CVPixelBuffer, pts: CMTime) {
        if (running) {
            let frame = VideoFrame(pixelBuffer: pixelBuffer, pts: pts)
            let _ = syncQueue.enqueue(frame)
        }
    }

    public func stop() {
        running = false
        guard let session: VTCompressionSession = session else { return }
        VTCompressionSessionInvalidate(session)
        self.session = nil
        isSpsAndPpsSend = false
        forceKey = false
        syncQueue.clear()
    }
    
    public func setVideoBitrateOnFly(bitrate: Int) {
        guard let session = self.session else { return }
        self.bitrate = bitrate
        let bitrateMode = if #available(iOS 16.0, *) {
            kVTCompressionPropertyKey_ConstantBitRate
        } else {
            kVTCompressionPropertyKey_AverageBitRate
        }
        VTSessionSetProperties(session, propertyDictionary: [
            bitrateMode: bitrate
        ] as CFDictionary)
    }
    
    private var videoCallback: VTCompressionOutputCallback = {(outputCallbackRefCon: UnsafeMutableRawPointer?, _: UnsafeMutableRawPointer?, status: OSStatus, flags: VTEncodeInfoFlags, sampleBuffer: CMSampleBuffer?) in
        guard let sampleBuffer = sampleBuffer else {
            print("nil buffer")
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
    
    /*
     In iOS H264 and H265 are in AVC format and could contain multiple frames.
     We need split frames and convert to annexB
    */
    private func getValidRawBuffer(sampleBuffer: CMSampleBuffer) {
        let keyFrame = isKeyFrame(sampleBuffer: sampleBuffer)
        
        if (keyFrame) {
            //write sps and pps
            guard let description = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }
            var parametersCount: Int = 0
            if (codec == .H264) {
                CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, parameterSetIndex: 0, parameterSetPointerOut: nil,
                        parameterSetSizeOut: nil, parameterSetCountOut: &parametersCount, nalUnitHeaderLengthOut: nil)
            } else if (codec == .H265) {
                CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(description, parameterSetIndex: 0, parameterSetPointerOut: nil,
                        parameterSetSizeOut: nil, parameterSetCountOut: &parametersCount, nalUnitHeaderLengthOut: nil)
            }
            if (codec == .H264 && parametersCount != 2 || codec == .H265 && parametersCount < 3) {
                print("unexpected video parameters \(parametersCount)")
                return
            }

            var vps: UnsafePointer<UInt8>?
            var vpsSize: Int = 0
            if (codec == .H265) {
                CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(description, parameterSetIndex: 0, parameterSetPointerOut: &vps,
                        parameterSetSizeOut: &vpsSize, parameterSetCountOut: nil, nalUnitHeaderLengthOut: nil)
            }
            var sps: UnsafePointer<UInt8>?
            var spsSize: Int = 0
            if (codec == .H264) {
                CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, parameterSetIndex: 0, parameterSetPointerOut: &sps,
                        parameterSetSizeOut: &spsSize, parameterSetCountOut: nil, nalUnitHeaderLengthOut: nil)
            } else if (codec == .H265) {
                CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(description, parameterSetIndex: 1, parameterSetPointerOut: &sps,
                        parameterSetSizeOut: &spsSize, parameterSetCountOut: nil, nalUnitHeaderLengthOut: nil)
            }
            var pps: UnsafePointer<UInt8>?
            var ppsSize: Int = 0
            if (codec == .H264) {
                CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, parameterSetIndex: 1, parameterSetPointerOut: &pps,
                        parameterSetSizeOut: &ppsSize, parameterSetCountOut: nil, nalUnitHeaderLengthOut: nil)
            } else if (codec == .H265) {
                CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(description, parameterSetIndex: 2, parameterSetPointerOut: &pps,
                        parameterSetSizeOut: &ppsSize, parameterSetCountOut: nil, nalUnitHeaderLengthOut: nil)
            }

            var vpsData: [UInt8]? = nil
            if (codec == .H265) {
                vpsData = [UInt8](NSData(bytes: vps, length: vpsSize))
            }
            let spsData = [UInt8](NSData(bytes: sps, length: spsSize))
            let ppsData = [UInt8](NSData(bytes: pps, length: ppsSize))

            if (!isSpsAndPpsSend) {
                threadOutput.async {
                    self.callback.onVideoInfo(sps: spsData, pps: ppsData,
                            vps: vpsData != nil ? vpsData : nil)
                }
                isSpsAndPpsSend = true
            }
        }
        convertBuffer(sampleBuffer: sampleBuffer)
    }

    /*
     H264/H265 AVC to annexB.
    */
    private func convertBuffer(sampleBuffer: CMSampleBuffer) {
        // handle frame data
        guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            return
        }

        let startCode = [UInt8](arrayLiteral: 0x00, 0x00, 0x00, 0x01)

        var lengthAtOffset: Int = 0
        var totalLength: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        if CMBlockBufferGetDataPointer(dataBuffer, atOffset: 0, lengthAtOffsetOut: &lengthAtOffset,
                totalLengthOut: &totalLength, dataPointerOut: &dataPointer) == noErr {
            var bufferOffset: Int = 0
            let avcHeaderLength = 4

            while bufferOffset < (totalLength - avcHeaderLength) {
                var naluLength: UInt32 = 0
                // first four character is NALUnit length
                memcpy(&naluLength, dataPointer?.advanced(by: bufferOffset), avcHeaderLength)

                // big endian to host endian. in iOS it's little endian
                naluLength = CFSwapInt32BigToHost(naluLength)

                let data: NSData = NSData(bytes: dataPointer?.advanced(by: bufferOffset + avcHeaderLength),
                        length: Int(naluLength))
                // move forward to the next NAL Unit
                bufferOffset += Int(avcHeaderLength)
                bufferOffset += Int(naluLength)

                var rawH264 = [UInt8](data)
                rawH264.insert(contentsOf: startCode, at: 0)
                let end = Date().millisecondsSince1970
                let elapsedMicroSeconds = (end - initTs) * 1000
                let frame = Frame(buffer: rawH264, timeStamp: UInt64(elapsedMicroSeconds))

                threadOutput.async {
                    self.callback.getVideoData(frame: frame)
                }
            }
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
