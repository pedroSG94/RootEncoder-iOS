import Foundation

public protocol ConnectCheckerRtsp {
    
    func onConnectionSuccessRtsp()
    
    func onConnectionFailedRtsp(reason: String)
    
    func onNewBitrateRtsp(bitrate: UInt64)
    
    func onDisconnectRtsp()
    
    func onAuthErrorRtsp()
    
    func onAuthSuccessRtsp()
}
