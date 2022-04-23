//
// Created by Pedro  on 28/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation

public class RecordController {

    private var status = Status.STOPPED
    private var writer: AVAssetWriter? = nil
    private var time = CMTime.zero
    enum Status {
        case STARTED
        case STOPPED
        case RECORDING
        case PAUSED
        case RESUMED
    }

    func startRecord(path: URL) {
        writer = createWriter(path: path)
        writer?.startWriting()
        writer?.startSession(atSourceTime: time)
        status = Status.STARTED
    }

    func stopRecord() {

    }

    func recordVideo(videoFrame: Frame) {

    }

    func recordAudio(audioFrame: Frame) {

    }

    func pauseRecord() {

    }

    func resumeRecord() {

    }

    func setVideoFormat() {

    }

    func setAudioFormat() {

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
            print("create writer failed")
        }
        return nil
    }
}