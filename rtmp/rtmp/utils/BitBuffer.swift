//
//  BitBuffer.swift
//  rtmp
//
//  Created by Pedro  on 24/3/24.
//

import Foundation
import common

public class BitBuffer {
    
    private let sizeBits = 8
    private let buffer: Array<UInt8>
    private var bufferPosition = 0
    private var bufferEnd = 0
    
    public init(buffer: Array<UInt8>) {
        self.buffer = buffer
        bufferEnd = buffer.count * sizeBits
    }
    
    func hasRemaining() -> Bool {
        bitRemaining() > 0
    }
    
    func bitRemaining() -> Int {
        bufferEnd - bufferPosition + 1
    }
    
    func getBool() -> Bool {
        getInt(i: 1) == 1
    }
    
    public func get(i: Int) -> UInt8 {
        UInt8(getLong(i: i))
    }
    
    func getShort(i: Int) -> UInt16 {
        UInt16(getLong(i: i))
    }
    
    func getInt(i: Int) -> UInt32 {
        UInt32(getLong(i: i))
    }
    
    func getLong(i: Int) -> UInt64 {
        if (!hasRemaining()) {
            return 0
        }
        let b = buffer[bufferPosition / sizeBits]
        let v = if (b < 0) {
            Int(Int(b) + 256)
        } else {
            Int(b)
        }
        let left = sizeBits - bufferPosition % sizeBits
        var rc: UInt64 = 0
        if (i <= left) {
            rc = UInt64((v << (bufferPosition % sizeBits) & 0xFF) >> ((bufferPosition % sizeBits + (left - i))))
        } else {
            let then = i - left
            rc = getLong(i: left)
            rc = rc << then
            rc += getLong(i: then)
        }
        
        return rc
    }
    
    func readUE() -> Int {
        var leadingZeroBits = 0
        while (!getBool()) {
            leadingZeroBits += 1
        }
        return if (leadingZeroBits > 0) {
            Int((1 << leadingZeroBits) - 1 + getInt(i: leadingZeroBits))
        } else {
            0
        }
    }
    
    public static func extractRbsp(buffer: Array<UInt8>, headerLength: Int) -> Array<UInt8> {
        let byteBuffer = ByteBuffer.wrap(bytes: buffer)
        let indices = byteBuffer.indicesOf(prefix: [0x00, 0x00, 0x03])
        
        let rbsp = ByteBuffer(capacity: byteBuffer.remaining())
        
        rbsp.put(bytes: byteBuffer, offset: 0, length: headerLength)
        
        var previous = byteBuffer.position
        indices.forEach { it in
            rbsp.put(bytes: byteBuffer, offset: previous, length: it + 2 - previous)
            previous = it + 3
        }
        rbsp.put(bytes: byteBuffer, offset: previous, length: byteBuffer.limit - previous)
        
        var result = rbsp.getBytes(count: rbsp.position)
        if (result == nil) {
            result = Array<UInt8>()
        }
        return result!
    }
}
