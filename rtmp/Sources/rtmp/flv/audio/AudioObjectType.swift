//
//  AudioObjectType.swift
//  app
//
//  Created by Pedro  on 16/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import Foundation

public enum AudioObjectType: UInt8 {
    case UNKNOWN = 0
    case AAC_MAIN = 1
    case AAC_LC = 2
    case AAC_SSR = 3
    case AAC_LTP = 4
    case AAC_SBR = 5
    case AAC_SCALABLE = 6
    case TWINQ_VQ = 7
    case CELP = 8
    case HXVC = 9
}
