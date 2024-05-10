//
// Created by Pedro  on 28/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation

public class RecordController {

    private var status = Status.STOPPED
    private var path: URL? = nil
    private var writer: AVAssetWriter? = nil
    private var videoInput: AVAssetWriterInput? = nil
    private var videoAdaptor: AVAssetWriterInputPixelBufferAdaptor? = nil
    private var audioInput: AVAssetWriterInput? = nil
    private var videoConfigured = true
    private var audioConfigured = true
    private var videoCodec = AVVideoCodecType.h264
    private var audioCodec = kAudioFormatMPEG4AAC
    private let queue = DispatchQueue(label: "RecordController")
    
    enum Status {
        case STARTED
        case STOPPED
        case RECORDING
        case PAUSED
        case RESUMED
    }

    func startRecord(path: URL) {
        queue.async {
            self.writer = self.createWriter(path: path)
            if (self.videoInput != nil && self.writer?.canAdd(self.videoInput!) == true) {
                self.writer?.add(self.videoInput!)
            }
            if (self.audioInput != nil && self.writer?.canAdd(self.audioInput!) == true) {
                self.writer?.add(self.audioInput!)
            }
            self.writer?.startWriting()
            self.status = Status.STARTED
        }
    }

    func stopRecord() {
        self.status = Status.STOPPED
        videoInput?.markAsFinished()
        audioInput?.markAsFinished()
        self.videoAdaptor = nil
        self.videoInput = nil
        self.audioInput = nil
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        writer?.finishWriting {
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
    }
    
    private func initialize(time: CMTime) {
        if (self.status == Status.STARTED) {
            self.writer?.startSession(atSourceTime: time)
            self.status = Status.RECORDING
        }
    }

    func recordVideo(buffer: CMSampleBuffer) {
        queue.async {
            self.initialize(time: buffer.presentationTimeStamp)
            if (self.status != Status.RECORDING) {
                return
            }
            if (self.videoInput?.isReadyForMoreMediaData == true) {
                self.videoInput?.append(buffer)
            }
        }
    }
    
    func recordVideo(pixelBuffer: CVPixelBuffer, pts: CMTime) {
        queue.async {
            self.initialize(time: pts)
            if (self.status != Status.RECORDING) {
                return
            }
            if (self.videoInput?.isReadyForMoreMediaData == true) {
                self.videoAdaptor?.append(pixelBuffer, withPresentationTime: pts)
            }
        }
    }

    func recordAudio(buffer: CMSampleBuffer) {
        queue.async {
            self.initialize(time: buffer.presentationTimeStamp)
            if (self.status != Status.RECORDING) {
                return
            }
            if (self.audioInput?.isReadyForMoreMediaData == true) {
                self.audioInput?.append(buffer)
            }
        }
    }

    func pauseRecord() {
        status = Status.PAUSED
    }

    func resumeRecord() {
        status = Status.RECORDING
    }


    func setVideoFormat(witdh: Int, height: Int, bitrate: Int) {
        queue.async {
            let videoSettings: [String : Any] = [
                AVVideoCodecKey: self.videoCodec,
                AVVideoWidthKey: witdh,
                AVVideoHeightKey: height
            ]
            
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            input.expectsMediaDataInRealTime = true
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
            self.videoInput = input
            self.videoAdaptor = adaptor
            self.videoConfigured = true
        }
    }

    func setAudioFormat(sampleRate: Int, channels: Int, bitrate: Int) {
        queue.async {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: self.audioCodec,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: channels
            ]
            let input = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            input.expectsMediaDataInRealTime = true
            self.audioInput = input
            self.audioConfigured = true
        }
    }
    
    func setVideoCodec(codec: VideoCodec) {
        videoCodec = switch codec {
        case VideoCodec.H264:
            AVVideoCodecType.h264
        case VideoCodec.H265:
            AVVideoCodecType.hevc
        default:
            AVVideoCodecType.h264 //TODO throw error
        }
    }
    
    func setAudioCodec(codec: AudioCodec) {
        audioCodec = switch codec {
        case AudioCodec.AAC:
            kAudioFormatMPEG4AAC
        case AudioCodec.G711:
            kAudioFormatALaw
        default:
            kAudioFormatLinearPCM // TODO throw error
        }
    }

    func isRunning() -> Bool {
        status == Status.STARTED
        || status == Status.RECORDING
        || status == Status.PAUSED
        || status == Status.RESUMED
    }

    func isRecording() -> Bool {
        status == Status.RECORDING
    }

    func getStatus() -> Status {
        status
    }

    private func createWriter(path: URL) -> AVAssetWriter? {
        do {
            return try AVAssetWriter(outputURL: path, fileType: .mp4)
        } catch {
        }
        return nil
    }
}
