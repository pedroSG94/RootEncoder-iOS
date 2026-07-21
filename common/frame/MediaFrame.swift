//
//  File.swift
//  RootEncoder
//
//  Created by Pedro  on 1/10/24.
//

import Foundation

public struct MediaFrame {
    public let data: [UInt8]
    public let info: Info
    public let type: MediaType

    public init(data: [UInt8], info: Info, type: MediaType) {
        self.data = data
        self.info = info
        self.type = type
    }

    public struct Info {
        public let offset: Int
        public let size: Int
        public let timestamp: UInt64

        public init(offset: Int, size: Int, timestamp: UInt64) {
            self.offset = offset
            self.size = size
            self.timestamp = timestamp
        }
    }

    public enum MediaType {
        case VIDEO
        case AUDIO
    }
}
