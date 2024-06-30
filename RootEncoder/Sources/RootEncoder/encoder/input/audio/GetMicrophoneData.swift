//
//  GetMicrophoneData.swift
//  app
//
//  Created by Mac on 04/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation

public protocol GetMicrophoneData {
    func getPcmData(frame: PcmFrame, time: AVAudioTime)
}
