//
//  AudioSpecificConfig.swift
//  app
//
//  Created by Pedro  on 16/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import Foundation

public class AudioSpecificConfig {

    private let type: UInt8
    private let sampleRate: Int
    private let channels: Int

    private let audioSamplingRates = [
        96000,  // 0
        88200,  // 1
        64000,  // 2
        48000,  // 3
        44100,  // 4
        32000,  // 5
        24000,  // 6
        22050,  // 7
        16000,  // 8
        12000,  // 9
        11025,  // 10
        8000,   // 11
        7350    // 12
    ]

    var size: Int { return 9 }

    init(type: UInt8, sampleRate: Int, channels: Int) {
        self.type = type
        self.sampleRate = sampleRate
        self.channels = channels
    }

    func write(buffer: inout [UInt8], offset: Int) {
        writeConfig(buffer: &buffer, offset: offset)
        writeAdts(buffer: &buffer, offset: offset + 2)
    }

    private func writeConfig(buffer: inout [UInt8], offset: Int) {
        let frequency = getFrequency()
        buffer[offset] = UInt8((Int(type) << 3) | (frequency >> 1))
        buffer[offset + 1] = UInt8((frequency << 7) & 0x80 | (channels << 3) & 0x78)
    }

    private func writeAdts(buffer: inout [UInt8], offset: Int) {
        let frequency = getFrequency()
        buffer[offset] = 0xFF
        buffer[offset + 1] = 0xF9
        buffer[offset + 2] = UInt8(((Int(type) - 1) << 6) | (frequency << 2) | (channels >> 2))
        buffer[offset + 3] = UInt8(((channels & 3) << 6) | (buffer.count >> 11))
        buffer[offset + 4] = UInt8((buffer.count & 0x7FF) >> 3)
        buffer[offset + 5] = UInt8(((buffer.count & 7) << 5) | 0x1F)
        buffer[offset + 6] = 0xFC
    }

    private func getFrequency() -> Int {
        guard let frequency = audioSamplingRates.firstIndex(of: sampleRate) else {
            return 4 //sanity check, if samplerate not found using default 44100
        }
        return frequency
    }
}
