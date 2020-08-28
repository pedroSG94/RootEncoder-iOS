import Foundation

public class RtspClient {
    
    private var socket: Socket?
    private var connectCheckerRtsp: ConnectCheckerRtsp?
    
    init(connectCheckerRtsp: ConnectCheckerRtsp) {
        self.connectCheckerRtsp = connectCheckerRtsp
    }
    
    func connect() {
        self.connectCheckerRtsp?.onConnectionSuccessRtsp()
    }
    
    func disconnect() {
        self.connectCheckerRtsp?.onDisconnectRtsp()
    }
}
