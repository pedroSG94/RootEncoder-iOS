//
//  FourCCPacketType.swift
//  rtmp
//
//  Created by Pedro  on 24/3/24.
//

import Foundation

public enum FourCCPacketType: Int {
    case SEQUENCE_START = 0
    case CODEC_FRAMES = 1
    case SEQUENCE_END = 2
    case CODED_FRAMES_X = 3
    case METADATA = 4
    case MPEG_2_TS_SEQUENCE_START = 5
}
