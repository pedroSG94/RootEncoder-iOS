import XCTest
@testable import RootEncoder

final class RootEncoderTests: XCTestCase {
    func testUrlParser() throws {
        do {
            let result = try UrlParser.parse(endpoint: "rtmp://a.rtmp.youtube.com/live2/xxxx-xxxx-xxxx-xxxx", requiredProtocols: ["rtmp"])
            assert(result.host == "a.rtmp.youtube.com")
            assert(result.getAppName() == "live2")
            assert(result.getStreamName() == "xxxx-xxxx-xxxx-xxxx")
            assert(result.scheme == "rtmp")
            assert(result.getTcUrl() == "rtmp://a.rtmp.youtube.com/live2")
        } catch {
            
        }
    }
}
