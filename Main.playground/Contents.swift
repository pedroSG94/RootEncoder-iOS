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
    private let commandsManager = CommandsManager()
    
    func testCommands() {
        let response = """
        RTSP/1.0 200 OK
        CSeq: 1
        Session: -TsTUgzgR
        Public: DESCRIBE, SETUP, TEARDOWN, PLAY, PAUSE, OPTIONS, ANNOUNCE, RECORD

        """
        commandsManager.getResponse(response: response, isAudio: false, connectCheckerRtsp: self)
    }
    
    init() {
        rtspClient = RtspClient(connectCheckerRtsp: self)
    }
    
    func test() {
        rtspClient?.setOnlyAudio(onlyAudio: true)
        rtspClient?.connect(url: self.url)
        rtspClient?.disconnect()
    }
}

Test().testCommands()
