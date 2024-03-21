import Foundation
import CryptoKit

extension Array {
    func get(destiny: inout Array, index: Int, length: Int) -> Array {
        var result = self
        for i in stride(from: 0, to: length, by: 1) {
            destiny[index + i] = result.remove(at: 0)
        }
        return result
    }
}

public extension String {
    var md5: String {
        let data = Data(utf8)
        let digestData = Insecure.MD5.hash (data: data)
        return String(digestData.map { String(format: "%02x", $0) }.joined())
    }
}

public func intToBytes<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
    withUnsafeBytes(of: value.littleEndian, Array.init)
}
