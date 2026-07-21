//
//  VideoDataType.swift
//  app
//
//  Created by Pedro  on 19/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import Common
import Foundation

public enum VideoDataType: UInt8 {
    case KEYFRAME = 1
    case INTER_FRAME = 2
}
