//
// Created by Pedro  on 28/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation
import encoder
import Photos

public class RecordController {

    private var status = Status.STOPPED
    private var path: URL? = nil
    private var writer: AVAssetWriter? = nil
    private var videoInput: AVAssetWriterInput? = nil
    private var audioInput: AVAssetWriterInput? = nil
    private var videoConfigured = false
    private var audioConfigured = true
    
    enum Status {
        case STARTED
        case STOPPED
        case RECORDING
        case PAUSED
        case RESUMED
    }

    func startRecord(path: URL) {
        writer = createWriter(path: path)
        if (writer == nil) {
            print("fail to create writer")
        }
        if (videoInput != nil && writer?.canAdd(videoInput!) == true) {
            writer?.add(videoInput!)
        } else {
            print("fail to add video track")
        }
        if (audioInput != nil && writer?.canAdd(audioInput!) == true) {
            writer?.add(audioInput!)
        } else {
            print("fail to add audio track")
        }
        let result = writer?.startWriting()
        if (result != true) {
            print("fail to start writer")
        }
        writer?.startSession(atSourceTime: .zero)
        if (videoConfigured && audioConfigured) {
            status = Status.RECORDING
        } else {
            status = Status.STARTED
        }
    }

    func stopRecord() {
        videoInput?.markAsFinished()
        audioInput?.markAsFinished()
        writer?.finishWriting {
            self.videoInput = nil
            self.audioInput = nil
            if (self.writer?.status == .completed) {
                PHPhotoLibrary.shared().performChanges({
                    guard let path = self.path else { return }
                    // Crear una solicitud para agregar el video a la biblioteca de fotos
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: path)
                }) { success, error in
                    if let error = error {
                        print("Error saving video to photo library: \(error)")
                    } else {
                        print("Video saved to photo library.")
                    }
                }
            } else {
                print("stop record failed: \(self.writer?.status.rawValue ?? -1)")
            }
        }

    }

    func recordVideo(buffer: CMSampleBuffer) {
        if (videoInput?.isReadyForMoreMediaData == true && status == Status.RECORDING) {
            videoInput?.append(buffer)
        }
    }

    func recordAudio(buffer: CMSampleBuffer) {
        if (audioInput?.isReadyForMoreMediaData == true && status == Status.RECORDING) {
            audioInput?.append(buffer)
        }
    }

    func pauseRecord() {
        status = Status.PAUSED
    }

    func resumeRecord() {
        status = Status.RECORDING
    }

    func setVideoFormat(witdh: Int, height: Int, bitrate: Int, codec: AVVideoCodecType) {
        // Configurar los ajustes de video
        let videoSettings: [String : Any] = [
            AVVideoCodecKey: codec,
            AVVideoWidthKey: witdh,
            AVVideoHeightKey: height
        ]
        
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput = input
        videoConfigured = true
    }

    func setAudioFormat(sampleRate: Int, channels: Int, bitrate: Int, codec: AudioFormatID) {
        let audioSettings: [String: Any] = [
            AVFormatIDKey: Int(codec), // Formato de audio MPEG4 AAC
            AVSampleRateKey: sampleRate, // Tasa de muestreo de audio (en Hz)
            AVNumberOfChannelsKey: channels, // Número de canales de audio (1 para mono, 2 para estéreo)
        ]
        let input = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioInput = input
        audioConfigured = true
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
