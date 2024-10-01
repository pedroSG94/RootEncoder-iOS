//
//  File.swift
//  RootEncoder
//
//  Created by Pedro  on 1/10/24.
//

import Foundation

public struct MediaFrame {
    let data: [UInt8]
    let info: Info
    let type: MediaType
    
    public struct Info {
        let offset: Int
        let size: Int
        let timestamp: UInt64
    }
    
    public enum MediaType {
        case VIDEO
        case AUDIO
    }
}

