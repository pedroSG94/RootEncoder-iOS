import Foundation

extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

extension String: Error {
    
}

public extension String {
    func groups(for regexPattern: String) -> [[String]] {
        do {
            let text = self
            let regex = try NSRegularExpression(pattern: regexPattern)
            let matches = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
            return matches.map { match in
                return (0..<match.numberOfRanges).map {
                    let rangeBounds = match.range(at: $0)
                    guard let range = Range(rangeBounds, in: text) else {
                        return ""
                    }
                    return String(text[range])
                }
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}

extension Socket {
    struct CircularBuffer: CustomDebugStringConvertible {
        var debugDescription: String {
            "Nothing"
        }
        
        var bytes: UnsafePointer<UInt8>? {
            data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> UnsafePointer<UInt8>? in
                bytes.baseAddress?.assumingMemoryBound(to: UInt8.self).advanced(by: head)
            }
        }
        var maxLength: Int {
            min(count, capacity - head)
        }

        private var count: Int {
            let value = tail - head
            return value < 0 ? value + capacity : value
        }
        private var data: Data
        private var capacity: Int = 0
        private var head: Int = 0
        private var tail: Int = 0
        private var locked: UnsafeMutablePointer<UInt32>?
        private var lockedTail: Int = -1
        private let baseCapacity: Int

        init(capacity: Int) {
            self.capacity = capacity
            baseCapacity = capacity
            data = .init(repeating: 0, count: capacity)
        }

        @discardableResult
        mutating func append(_ data: Data, locked: UnsafeMutablePointer<UInt32>? = nil) -> Bool {
            guard data.count + count < capacity else {
                return resize(data)
            }
            let count = data.count
            if self.locked == nil {
                self.locked = locked
            }
            let length = min(count, capacity - tail)
            return self.data.withUnsafeMutableBytes { (bytes: UnsafeMutableRawBufferPointer) -> Bool in
                guard let pointer = bytes.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    return false
                }
                data.copyBytes(to: pointer.advanced(by: tail), count: length)
                if length < count {
                    tail = count - length
                    data.advanced(by: length).copyBytes(to: pointer, count: tail)
                } else {
                    tail += count
                }
                if capacity == tail {
                    tail = 0
                }
                if locked != nil {
                    lockedTail = tail
                }
                return true
            }
        }

        mutating func skip(_ count: Int) {
            let length = min(count, capacity - head)
            if length < count {
                head = count - length
            } else {
                head += count
            }
            if capacity == head {
                head = 0
            }
            if let locked = locked, -1 < lockedTail && lockedTail <= head {
                OSAtomicAnd32Barrier(0, locked)
                lockedTail = -1
            }
        }

        mutating func clear() {
            head = 0
            tail = 0
            locked = nil
            lockedTail = 0
        }

        private mutating func resize(_ data: Data) -> Bool {
            if 0 < head {
                let subdata = self.data.subdata(in: 0..<tail)
                self.data.replaceSubrange(0..<capacity - head, with: self.data.advanced(by: head))
                self.data.replaceSubrange(capacity - head..<capacity - head + subdata.count, with: subdata)
                tail = capacity - head + subdata.count
            }
            self.data.append(.init(count: baseCapacity))
            head = 0
            capacity = self.data.count
            return append(data)
        }
    }
}
