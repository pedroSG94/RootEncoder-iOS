//
//  Extensions.swift
//  common
//
//  Created by Pedro  on 20/3/24.
//

import Foundation
import CryptoKit


public extension Array {
    mutating func get(destiny: inout Array, index: Int, length: Int) {
        destiny[index...index + length - 1] = self[0...length - 1]
        self.removeFirst(length)
    }
}

public extension Date {
    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

public extension String {
    subscript (range: Range<Int>) -> Substring {
        let startIndex = self.index(self.startIndex, offsetBy: range.startIndex)
        let stopIndex = self.index(self.startIndex, offsetBy: range.startIndex + range.count)
        return self[startIndex..<stopIndex]
    }
    func groups(for regexPattern: String) -> [[String]] {
        do {
            let text = self
            let regex = try NSRegularExpression(pattern: regexPattern)
            let matches = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
            return matches.map { match in
                (0..<match.numberOfRanges).map {
                    let rangeBounds = match.range(at: $0)
                    guard let range = Range(rangeBounds, in: text) else {
                        return ""
                    }
                    return String(text[range])
                }
            }
        } catch _ {
            return []
        }
    }
    var md5: String {
        let data = Data(utf8)
        let digestData = Insecure.MD5.hash(data: data)
        return String(digestData.map { String(format: "%02x", $0) }.joined())
    }
    
    var md5Base64: String {
        let data = Data(utf8)
        let digestData = Data(Insecure.MD5.hash(data: data))
        return digestData.base64EncodedString()
    }
}

public func intToBytes<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
    withUnsafeBytes(of: value.littleEndian, Array.init)
}

public extension VideoEncoder {
    func createStreamClientListener() -> StreamClientListener {
        class StreamClientHandler: StreamClientListener {
            
            private let encoder: VideoEncoder
            
            init(encoder: VideoEncoder) {
                self.encoder = encoder
            }
            
            func onRequestKeyframe() {
                encoder.forceKeyFrame()
            }
        }
        return StreamClientHandler(encoder: self)
    }
}
