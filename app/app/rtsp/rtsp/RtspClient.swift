import Foundation

public class RtspClient {
    
    private var socket: Socket?
    private var connectCheckerRtsp: ConnectCheckerRtsp?
    private var streaming = false
    private let commandsManager = CommandsManager()
    private var tlsEnabled = false
    private var isOnlyAudio = false
    private var rtpSender: RtpSender?
    private var sps: Array<UInt8>? = nil, pps: Array<UInt8>? = nil
    
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
    
    public func setVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        self.sps = sps
        self.pps = pps
        let spsString = Data(sps).base64EncodedString()
        let ppsString = Data(pps).base64EncodedString()
        commandsManager.setVideoConfig(sps: spsString, pps: ppsString, vps: nil)
    }
    
    public func connect(url: String) {
        let thread = DispatchQueue(label: "RtspClient")
        thread.async {
            if !self.streaming {
                let urlResults = url.groups(for: "^rtsps?://([^/:]+)(?::(\\d+))*/([^/]+)/?([^*]*)$")
                if urlResults.count > 0 {
                    let groups = urlResults[0]
                    self.tlsEnabled = groups[0].hasPrefix("rtsps")
                    let host = groups[1]
                    let defaultPort = groups.count == 3
                    let port = defaultPort ? 554 : Int(groups[2])!
                    let path = "/\(groups[defaultPort ? 2 : 3])/\(groups[defaultPort ? 3 : 4])"
                    self.commandsManager.setUrl(host: host, port: port, path: path)
                    self.socket = Socket(tlsEnabled: self.tlsEnabled, host: host, port: port, callback: self.connectCheckerRtsp!)
                    self.socket?.connect()
                    self.rtpSender = RtpSender(socket: self.socket!)
                    //Options
                    self.socket?.write(data: self.commandsManager.createOptions())
                    let optionsResponse = self.socket?.read()
                    self.commandsManager.getResponse(response: optionsResponse!, isAudio: false, connectCheckerRtsp: self.connectCheckerRtsp)
                    //Announce
                    self.socket?.write(data: self.commandsManager.createAnnounce())
                    let announceResponse = self.socket?.read()
                    self.commandsManager.getResponse(response: announceResponse!, isAudio: false, connectCheckerRtsp: self.connectCheckerRtsp)
                    let status = self.commandsManager.getResonseStatus(response: announceResponse!)
                    print("s: \(status)")
                    if status == 403 {
                        self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, access denied")
                    } else if status == 401 {
                        if (self.commandsManager.canAuth()) {
                            //Announce with auth
                            self.socket?.write(data: self.commandsManager.createAuth(authResponse: announceResponse!))
                            let authResponse = self.socket?.read()
                            let authStatus = self.commandsManager.getResonseStatus(response: authResponse!)
                            if authStatus == 401 {
                                self.connectCheckerRtsp?.onAuthErrorRtsp()
                            } else if authStatus == 200 {
                                self.connectCheckerRtsp?.onAuthSuccessRtsp()
                            } else {
                                self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, announce with auth failed \(authStatus)")
                            }
                        } else {
                            self.connectCheckerRtsp?.onAuthErrorRtsp()
                        }
                    } else if status != 200 {
                        self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, announce with auth failed \(status)")
                    }
                    if !self.isOnlyAudio {
                        //Setup video
                        self.rtpSender?.setVideoInfo(sps: self.sps!, pps: self.pps!)
                        self.socket?.write(data: self.commandsManager.createSetup(track: self.commandsManager.getVideoTrack()))
                        let videoSetupResponse = self.socket?.read()
                        self.commandsManager.getResponse(response: videoSetupResponse!, isAudio: false, connectCheckerRtsp: self.connectCheckerRtsp)
                    }
                    //Setup audio
                    self.socket?.write(data: self.commandsManager.createSetup(track: self.commandsManager.getAudioTrack()))
                    let audioSetupResponse = self.socket?.read()
                    self.commandsManager.getResponse(response: audioSetupResponse!, isAudio: true, connectCheckerRtsp: self.connectCheckerRtsp)
                    //Record
                    self.socket?.write(data: self.commandsManager.createRecord())
                    let recordResponse = self.socket?.read()
                    self.commandsManager.getResponse(response: recordResponse!, isAudio: false, connectCheckerRtsp: self.connectCheckerRtsp)
                    self.streaming = true
                    self.rtpSender?.setAudioInfo(sampleRate: self.commandsManager.getSampleRate())
                    self.rtpSender?.start()
                    self.connectCheckerRtsp?.onConnectionSuccessRtsp()
                } else {
                    self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Endpoint malformed, should be: rtsp://ip:port/appname/streamname")
                    return
                }
            }
        }
    }
    
    public func isStreaming() -> Bool {
        return streaming
    }
    
    public func disconnect() {
        if streaming {
            rtpSender?.stop()
            socket?.write(data: commandsManager.createTeardown())
            socket?.disconnect()
            commandsManager.reset()
            streaming = false
            connectCheckerRtsp?.onDisconnectRtsp()
        }
    }
    
    public func sendVideo(frame: Frame) {
        if (streaming) {
            rtpSender?.sendVideo(frame: frame)
        }
    }
    
    public func sendAudio(frame: Frame) {
        if (streaming) {
            rtpSender?.sendAudio(frame: frame)
        }
    }
}
