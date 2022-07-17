//
// Created by Pedro  on 17/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public class RtmpCamera: CameraBase {

    private var client: RtmpClient!

    public init(view: UIView, connectChecker: ConnectCheckerRtmp) {
        client = RtmpClient(connectCheckerRtmp: connectChecker)
        super.init(view: view)
    }

    public func setAuth(user: String, password: String) {
        //client.setAuth(user: user, password: password)
    }

    public func setCodec(codec: CodecUtil) {
        videoEncoder.setCodec(codec: codec)
    }

    public override func prepareAudioRtp(sampleRate: Int, isStereo: Bool) {
        super.prepareAudioRtp(sampleRate: sampleRate, isStereo: isStereo)
        client.setAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
    }

    public override func stopStreamRtp() {
        client.disconnect()
    }

    public override func getAacDataRtp(frame: Frame) {
        //client.sendAudio(frame: frame)
    }

    public override func getH264DataRtp(frame: Frame) {
        //client.sendVideo(frame: frame)
    }

    public override func onSpsPpsVpsRtp(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        client.setVideoInfo(sps: sps, pps: pps, vps: vps)
        client.connect(url: endpoint)
    }
}