import XCTest
@testable import RootEncoder

final class RootEncoderTests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
    }
    
    func testG711Encode() throws {
        let pcmBuffer: Array<UInt8> = [0x18, 0x30, 0x40, 0x58]
        let g711Buffer: Array<UInt8> = [0xbd, 0xa3]
        let codec = G711Codec()
        try codec.configure(sampleRate: 8000, channels: 1)
        let result = codec.encode(buffer: pcmBuffer, offset: 0, size: pcmBuffer.count)
        print(result)
        print(g711Buffer)
        assert(result == g711Buffer)
    }
    
    func testG711Decode() throws {
        let pcmBuffer: Array<UInt8> = [0x18, 0x30, 0x40, 0x58]
        let g711Buffer: Array<UInt8> = [0xbd, 0xa3]
        let codec = G711Codec()
        try codec.configure(sampleRate: 8000, channels: 1)
        let result = codec.decode(buffer: g711Buffer, offset: 0, size: g711Buffer.count)
        assert(result == pcmBuffer)
    }
}
