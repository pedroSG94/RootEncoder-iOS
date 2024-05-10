//
//  AudioFormat.swift
//  app
//
//  Created by Pedro  on 16/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import Foundation

public enum AudioFormat: UInt8 {
    case PCM = 0
    case ADPCM = 1
    case MP3 = 2
    case PCM_LE = 3
    case NELLYMOSER_16K = 4
    case NELLYMOSER_8K = 5
    case NELLYMOSER = 6
    case G711_A = 7
    case G711_MU = 8
    case RESERVED = 9
    case AAC = 10
    case SPEEX = 11
    case MP3_8K = 14
    case DEVICE_SPECIFIC = 15
}
