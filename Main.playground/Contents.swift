import UIKit
import Main_Sources

class Test: ConnectCheckerRtsp {
    func onConnectionSuccessRtsp() {
        print("connection success")
    }
    
    func onConnectionFailedRtsp(reason: String) {
        print("connection failed: \(reason)")
    }
    
    func onNewBitrateRtsp(bitrate: UInt64) {
        print("new bitrate: \(bitrate)")
    }
    
    func onDisconnectRtsp() {
        print("disconnected")
    }
    
    func onAuthErrorRtsp() {
        print("auth error")
    }
    
    func onAuthSuccessRtsp() {
        print("auth success")
    }
    
    let url = "rtsp://192.168.0.32:554/live/pedro"
    var rtspClient: RtspClient? = nil
    
    init() {
        rtspClient = RtspClient(connectCheckerRtsp: self)
    }
    
    func test() {
        rtspClient?.setAudioInfo(sampleRate: 44100, isStereo: true)
        rtspClient?.setVideoInfo(sps: "Z0KAHtoHgUZA", pps: "aM4NiA==", vps: nil)
        rtspClient?.connect(url: self.url)
        rtspClient?.disconnect()
    }
}

Test().test()
