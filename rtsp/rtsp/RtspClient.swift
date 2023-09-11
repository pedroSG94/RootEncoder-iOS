import Foundation

public class RtspClient {
    
    private var socket: Socket?
    private var connectCheckerRtsp: ConnectCheckerRtsp?
    private var streaming = false
    private let commandsManager = CommandsManager()
    private var tlsEnabled = false
    private let rtspSender: RtspSender
    private var sps: Array<UInt8>? = nil, pps: Array<UInt8>? = nil, vps: Array<UInt8>? = nil
    
    public init(connectCheckerRtsp: ConnectCheckerRtsp) {
        self.connectCheckerRtsp = connectCheckerRtsp
        rtspSender = RtspSender(callback: connectCheckerRtsp)
    }
    
    public func setAuth(user: String, password: String) {
        commandsManager.setAuth(user: user, password: password)
    }

    public func setProtocol(mProtocol: Protocol) {
        commandsManager.mProtocol = mProtocol
    }

    public func setOnlyAudio(onlyAudio: Bool) {
        commandsManager.isOnlyAudio = onlyAudio
    }
    
    public func setAudioInfo(sampleRate: Int, isStereo: Bool) {
        commandsManager.setAudioConfig(sampleRate: sampleRate, isStereo: isStereo)
    }
    
    public func setVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        self.sps = sps
        self.pps = pps
        self.vps = vps
        let spsString = Data(sps).base64EncodedString()
        let ppsString = Data(pps).base64EncodedString()
        let vpsString = vps != nil ? Data(vps!).base64EncodedString() : nil
        commandsManager.setVideoConfig(sps: spsString, pps: ppsString, vps: vpsString)
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
                    do {
                        self.socket = Socket(tlsEnabled: self.tlsEnabled, host: host, port: port)
                        try self.socket?.connect()
                        //Options
                        try self.socket?.write(data: self.commandsManager.createOptions())
                        let optionsResponse = try self.socket?.readString()
                        let optionsStatus = self.commandsManager.getResponse(response: optionsResponse!, isAudio: false)
                        if (optionsStatus != 200) {
                            self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, options \(optionsStatus)")
                            return
                        }
                        //Announce
                        try self.socket?.write(data: self.commandsManager.createAnnounce())
                        let announceResponse = try self.socket?.readString()
                        let announceStatus = self.commandsManager.getResponse(response: announceResponse!, isAudio: false)
                        if announceStatus == 403 {
                            self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, access denied")
                        } else if announceStatus == 401 {
                            if (self.commandsManager.canAuth()) {
                                //Announce with auth
                                try self.socket?.write(data: self.commandsManager.createAnnounceWithAuth(authResponse: announceResponse!))
                                let authResponse = try self.socket?.readString()
                                let authStatus = self.commandsManager.getResponse(response: authResponse!, isAudio: false)
                                if authStatus == 401 {
                                    self.connectCheckerRtsp?.onAuthErrorRtsp()
                                } else if authStatus == 200 {
                                    self.connectCheckerRtsp?.onAuthSuccessRtsp()
                                } else {
                                    self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, announce with auth failed \(authStatus)")
                                }
                            } else {
                                self.connectCheckerRtsp?.onAuthErrorRtsp()
                                return
                            }
                        } else if announceStatus != 200 {
                            self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, announce with auth failed \(announceStatus)")
                        }
                        if !self.commandsManager.isOnlyAudio {
                            //Setup video
                            self.rtspSender.setVideoInfo(sps: self.sps!, pps: self.pps!, vps: self.vps)
                            try self.socket?.write(data: self.commandsManager.createSetup(track: self.commandsManager.getVideoTrack()))
                            let videoSetupResponse = try self.socket?.readString()
                            let setupAudioStatus = self.commandsManager.getResponse(response: videoSetupResponse!, isAudio: false)
                            if (setupAudioStatus != 200) {
                                self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, setup audio \(setupAudioStatus)")
                                return
                            }
                        }
                        //Setup audio
                        try self.socket?.write(data: self.commandsManager.createSetup(track: self.commandsManager.getAudioTrack()))
                        let audioSetupResponse = try self.socket?.readString()
                        let setupVideoStatus = self.commandsManager.getResponse(response: audioSetupResponse!, isAudio: true)
                        if (setupVideoStatus != 200) {
                            self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, setup video \(setupVideoStatus)")
                            return
                        }
                        //Record
                        try self.socket?.write(data: self.commandsManager.createRecord())
                        let recordResponse = try self.socket?.readString()
                        let recordStatus = self.commandsManager.getResponse(response: recordResponse!, isAudio: false)
                        if (recordStatus != 200) {
                            self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, record \(recordStatus)")
                            return
                        }
                        self.streaming = true
                        self.rtspSender.setAudioInfo(sampleRate: self.commandsManager.getSampleRate())

                        self.rtspSender.setSocketInfo(mProtocol: self.commandsManager.mProtocol, socket: self.socket!,
                                videoClientPorts: self.commandsManager.videoClientPorts, audioClientPorts: self.commandsManager.audioClientPorts,
                                videoServerPorts: self.commandsManager.videoServerPorts, audioServerPorts: self.commandsManager.audioServerPorts)
                        self.rtspSender.start()
                        self.connectCheckerRtsp?.onConnectionSuccessRtsp()
                    } catch let error {
                        self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: error.localizedDescription)
                        return
                    }
                } else {
                    self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Endpoint malformed, should be: rtsp://ip:port/appname/streamname")
                    return
                }
            }
        }
    }
    
    public func isStreaming() -> Bool {
        streaming
    }
    
    public func disconnect() {
        if streaming {
            rtspSender.stop()
            do {
                try socket?.write(data: commandsManager.createTeardown())
            } catch {
            }
            socket?.disconnect()
            commandsManager.reset()
            streaming = false
            connectCheckerRtsp?.onDisconnectRtsp()
        }
    }
    
    public func sendVideo(frame: Frame) {
        if (streaming && !commandsManager.isOnlyAudio) {
            rtspSender.sendVideo(frame: frame)
        }
    }
    
    public func sendAudio(frame: Frame) {
        if (streaming) {
            rtspSender.sendAudio(frame: frame)
        }
    }
}
