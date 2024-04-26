//
// Created by Pedro  on 25/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation
import VideoToolbox

public enum CodecUtil {
    case H264
    case H265

    var value: CMVideoCodecType {
        switch self {
        case .H264:
            return kCMVideoCodecType_H264
        case .H265:
            return kCMVideoCodecType_HEVC
        }
    }

    var profile: CFString {
        switch self {
        case .H264:
            return kVTProfileLevel_H264_Baseline_AutoLevel
        case .H265:
            return kVTProfileLevel_HEVC_Main_AutoLevel
        }
    }
}
