//
// Created by Pedro  on 12/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public struct RtmpConfig {
    public static let DEFAULT_CHUNK_SIZE = 128
    public static var writeChunkSize = DEFAULT_CHUNK_SIZE
    public static var acknowledgementWindowSize = 0
}