import Foundation

public class RtspClient {
    
    private var socket: Socket?
    private var connectCheckerRtsp: ConnectCheckerRtsp?
    private var streaming = false
    private let commandsManager = CommandsManager()
    private var tlsEnabled = false
    private var isOnlyAudio = false
    private var rtpSender: RtpSender?
    
    public init(connectCheckerRtsp: ConnectCheckerRtsp) {
        self.connectCheckerRtsp = connectCheckerRtsp
    }
    
    public func setAuth(user: String, password: String) {
        commandsManager.setAuth(user: user, password: password)
    }
    
    public func setOnlyAudio(onlyAudio: Bool) {
        self.isOnlyAudio = onlyAudio
    }
    
    public func setAudioInfo(sampleRate: Int, isStereo: Bool) {
        commandsManager.setAudioConfig(sampleRate: sampleRate, isStereo: isStereo)
    }
    
    public func setVideoInfo(sps: String, pps: String, vps: String?) {
        commandsManager.setVideoConfig(sps: sps, pps: pps, vps: vps)
    }
    
    public func connect(url: String) {
        if !streaming {
            let urlResults = url.groups(for: "^rtsps?://([^/:]+)(?::(\\d+))*/([^/]+)/?([^*]*)$")
            if urlResults.count > 0 {
                let groups = urlResults[0]
                self.tlsEnabled = groups[0].hasPrefix("rtsps")
                let host = groups[1]
                let defaultPort = groups.count == 3
                let port = defaultPort ? 554 : Int(groups[2])!
                let path = "/\(groups[defaultPort ? 2 : 3])/\(groups[defaultPort ? 3 : 4])"
                self.commandsManager.setUrl(host: host, port: port, path: path)
                socket = Socket(host: host, port: port)
                socket?.connect()
                rtpSender = RtpSender(socket: socket!)
                //Options
                socket?.write(data: commandsManager.createOptions())
                let optionsResponse = socket?.readBlock(blockTime: 1000)
                commandsManager.getResponse(response: optionsResponse!, isAudio: false, connectCheckerRtsp: self.connectCheckerRtsp)
                //Announce
                socket?.write(data: commandsManager.createAnnounce())
                let announceResponse = socket?.readBlock(blockTime: 1000)
                commandsManager.getResponse(response: announceResponse!, isAudio: false, connectCheckerRtsp: self.connectCheckerRtsp)
                let status = commandsManager.getResonseStatus(response: announceResponse!)
                if status == 403 {
                    connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, access denied")
                } else if status == 401 {
                    if (commandsManager.canAuth()) {
                        //Announce with auth
                        socket?.write(data: commandsManager.createAuth(authResponse: announceResponse!))
                        let authResponse = socket?.readBlock(blockTime: 1000)
                        let authStatus = commandsManager.getResonseStatus(response: authResponse!)
                        if authStatus == 401 {
                            connectCheckerRtsp?.onAuthErrorRtsp()
                        } else if authStatus == 200 {
                            connectCheckerRtsp?.onAuthSuccessRtsp()
                        } else {
                            connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, announce with auth failed \(authStatus)")
                        }
                    } else {
                        connectCheckerRtsp?.onAuthErrorRtsp()
                    }
                } else if status != 200 {
                    connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, announce with auth failed \(status)")
                }
                //Setup audio
                socket?.write(data: commandsManager.createSetup(track: commandsManager.getAudioTrack()))
                let audioSetupResponse = socket?.readBlock(blockTime: 1000)
                commandsManager.getResponse(response: audioSetupResponse!, isAudio: true, connectCheckerRtsp: self.connectCheckerRtsp)
                if !isOnlyAudio {
                    //Setup video
                    socket?.write(data: commandsManager.createSetup(track: commandsManager.getVideoTrack()))
                    let videoSetupResponse = socket?.readBlock(blockTime: 1000)
                    commandsManager.getResponse(response: videoSetupResponse!, isAudio: false, connectCheckerRtsp: self.connectCheckerRtsp)
                }
                //Record
                socket?.write(data: commandsManager.createRecord())
                let recordResponse = socket?.readBlock(blockTime: 1000)
                commandsManager.getResponse(response: recordResponse!, isAudio: false, connectCheckerRtsp: self.connectCheckerRtsp)
                self.streaming = true
                rtpSender?.setAudioInfo(sampleRate: commandsManager.getSampleRate())
                self.connectCheckerRtsp?.onConnectionSuccessRtsp()
            } else {
                self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Endpoint malformed, should be: rtsp://ip:port/appname/streamname")
                return
            }
        }
    }
    
    public func disconnect() {
        if streaming {
            socket?.write(data: commandsManager.createTeardown())
            socket?.disconnect()
            commandsManager.reset()
            self.streaming = false
            self.connectCheckerRtsp?.onDisconnectRtsp()
        }
    }
    
    public func sendVideo(buffer: Array<UInt8>, ts: UInt64) {
        rtpSender?.sendVideo(buffer: buffer, ts: ts)
    }
    
    public func sendAudio(buffer: Array<UInt8>, ts: UInt64) {
        if (streaming) {
            rtpSender?.sendAudio(buffer: buffer, ts: ts)
        }
    }
}
