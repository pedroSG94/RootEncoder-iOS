//
//  VideoNalType.swift
//  app
//
//  Created by Pedro  on 19/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import Foundation

public enum VideoNalType: UInt8 {
    //H264
    case UNSPEC = 0
    case SLICE = 1
    case DPA = 2
    case DPB = 3
    case DPC = 4
    case IDR = 5
    case SEI = 6
    case SPS = 7
    case PPS = 8
    case AUD = 9
    case EO_SEQ = 10
    case EO_STREAM = 11
    case FILL = 12
    //H265
    case HEVC_VPS = 32
    case HEVC_SPS = 33
    case HEVC_PPS = 34
    //H265 IDR
    case IDR_N_LP = 20
    case IDR_W_DLP = 19
}
