//
//  VideoFormat.swift
//  app
//
//  Created by Pedro  on 19/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import Foundation

public enum VideoFormat: Int {
    case SORENSON_H263 = 2
    case SCREEN_1 = 3
    case VP6 = 4
    case VP6_ALPHA = 5
    case SCREEN_2 = 6
    case AVC = 7
    case UNKNOWN = 255
    //fourCC extension
    case HEVC = 1752589105 // { "h", "v", "c", "1" }
    case AV1 = 1635135537 // { "a", "v", "0", "1" }
    case VP9 = 1987063865 // { "v", "p", "0", "9" }
}
