//
//  ByteBuffer.swift
//  common
//
//  Created by Pedro  on 24/3/24.
//

import Foundation

public class ByteBuffer {
    
    private var data: Data
    public var position: Int
    public var limit: Int

    public init(capacity: Int) {
        data = Data(count: capacity)
        position = 0
        limit = capacity
    }

    public func put(byte: UInt8) {
        guard position < limit else { return }
        data[position] = byte
        position += 1
    }

    public func put(bytes: [UInt8]) {
        for byte in bytes {
            put(byte: byte)
        }
    }
    
    public func put(bytes: Array<UInt8>, offset: Int, length: Int) {
        data.append(contentsOf: bytes[offset...length - 1])
    }
    
    public func put(bytes: Data, offset: Int, length: Int) {
        put(bytes: [UInt8](bytes), offset: offset, length: length)
    }
    
    public func put(bytes: ByteBuffer, offset: Int, length: Int) {
        put(bytes: bytes.data, offset: offset, length: length)
    }

    public func get() -> UInt8? {
        guard position < limit else { return nil }
        let byte = data[position]
        position += 1
        return byte
    }
    
    public func get(index: Int) -> UInt8 {
        return data[index]
    }

    public func getBytes(count: Int) -> [UInt8]? {
        guard position + count <= limit else { return nil }
        let bytes = [UInt8](data[position..<position + count])
        position += count
        return bytes
    }

    public func rewind() {
        position = 0
    }

    public func flip() {
        position = 0
    }

    public func limit(_ newLimit: Int) {
        limit = max(0, min(newLimit, data.count))
    }
    
    public func remaining() -> Int {
        return limit - position
    }
    
    public func indicesOf(prefix: Array<UInt8>) -> Array<Int> {
        guard !prefix.isEmpty else {
            return []
        }
        var indices = [Int]()

        outer: for i in 0..<data.count - prefix.count + 1 {
            for j in prefix.indices {
                if self.get(index: i + j) != prefix[j] {
                    continue outer
                }
            }
            indices.append(i)
        }
        return indices
    }
    
    public static func wrap(bytes: Array<UInt8>) -> ByteBuffer {
        let byteBuffer = ByteBuffer(capacity: bytes.count)
        byteBuffer.put(bytes: bytes)
        return byteBuffer
    }
}
