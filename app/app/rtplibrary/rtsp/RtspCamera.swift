//
// Created by Pedro  on 21/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public class RtspCamera: CameraBase {

    private var client: RtspClient!

    public init(view: UIView, connectChecker: ConnectCheckerRtsp) {
        client = RtspClient(connectCheckerRtsp: connectChecker)
        super.init(view: view)
    }

    public override func prepareAudioRtp(sampleRate: Int, isStereo: Bool) {
        super.prepareAudioRtp(sampleRate: sampleRate, isStereo: isStereo)
        client.setAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
    }

    public override func stopStreamRtp() {
        client.disconnect()
    }

    public override func getAacDataRtp(frame: Frame) {
        client.sendAudio(frame: frame)
    }

    public override func getH264DataRtp(frame: Frame) {
        client.sendVideo(frame: frame)
    }

    public override func onSpsPpsVpsRtp(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        client.setVideoInfo(sps: sps, pps: pps, vps: vps)
        client.connect(url: endpoint)
    }
}
