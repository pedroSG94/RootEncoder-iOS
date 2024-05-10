import Foundation

extension Array {
    func get(destiny: inout Array, index: Int, length: Int) -> Array {
        var result = self
        for i in stride(from: 0, to: length, by: 1) {
            destiny[index + i] = result.remove(at: 0)
        }
        return result
    }
}
