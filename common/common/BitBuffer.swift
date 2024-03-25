//
//  BitBuffer.swift
//  common
//
//  Created by Pedro  on 25/3/24.
//

import Foundation

public class BitBuffer {
    
    private let buffer: Array<UInt8>

    public init(buffer: Array<UInt8>) {
        self.buffer = buffer
    }

    public func getBits(offset: Int, size: Int) -> Int {
        let startIndex = offset / 8
        let startBit = offset % 8
        var result = 0
        var bitNum = startBit

        for i in 0..<size {
            let nextByte = (startBit + i) % 8 < startBit
            let currentIndex = startIndex + (nextByte ? 1 : 0)
            let currentBit = (startBit + i) % 8
            let bitValue = (Int(buffer[currentIndex]) >> (7 - currentBit)) & 0x01
            result = (result << 1) | bitValue
            bitNum += 1
        }
        return result
    }
}
