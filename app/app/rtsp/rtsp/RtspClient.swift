import Foundation

public class RtspClient {
    
    private var socket: Socket?
    private var connectCheckerRtsp: ConnectCheckerRtsp?
    private var streaming = false
    private let commandsManager = CommandsManager()
    private var tlsEnabled = false
    private var rtpSender = RtpSender()
    private var sps: Array<UInt8>? = nil, pps: Array<UInt8>? = nil, vps: Array<UInt8>? = nil
    
    public init(connectCheckerRtsp: ConnectCheckerRtsp) {
        self.connectCheckerRtsp = connectCheckerRtsp
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
                    self.socket = Socket(tlsEnabled: self.tlsEnabled, host: host, port: port, callback: self.connectCheckerRtsp!)
                    self.socket?.connect()
                    //Options
                    self.socket?.write(data: self.commandsManager.createOptions())
                    let optionsResponse = self.socket?.read()
                    let optionsStatus = self.commandsManager.getResponse(response: optionsResponse!, isAudio: false)
                    if (optionsStatus != 200) {
                        self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, options \(optionsStatus)")
                        return
                    }
                    //Announce
                    self.socket?.write(data: self.commandsManager.createAnnounce())
                    let announceResponse = self.socket?.read()
                    let announceStatus = self.commandsManager.getResponse(response: announceResponse!, isAudio: false)
                    if announceStatus == 403 {
                        self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, access denied")
                    } else if announceStatus == 401 {
                        if (self.commandsManager.canAuth()) {
                            //Announce with auth
                            self.socket?.write(data: self.commandsManager.createAnnounceWithAuth(authResponse: announceResponse!))
                            let authResponse = self.socket?.read()
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
                        self.rtpSender.setVideoInfo(sps: self.sps!, pps: self.pps!, vps: self.vps)
                        self.socket?.write(data: self.commandsManager.createSetup(track: self.commandsManager.getVideoTrack()))
                        let videoSetupResponse = self.socket?.read()
                        let setupAudioStatus = self.commandsManager.getResponse(response: videoSetupResponse!, isAudio: false)
                        if (setupAudioStatus != 200) {
                            self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, setup audio \(setupAudioStatus)")
                            return
                        }
                    }
                    //Setup audio
                    self.socket?.write(data: self.commandsManager.createSetup(track: self.commandsManager.getAudioTrack()))
                    let audioSetupResponse = self.socket?.read()
                    let setupVideoStatus = self.commandsManager.getResponse(response: audioSetupResponse!, isAudio: true)
                    if (setupVideoStatus != 200) {
                        self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, setup video \(setupVideoStatus)")
                        return
                    }
                    //Record
                    self.socket?.write(data: self.commandsManager.createRecord())
                    let recordResponse = self.socket?.read()
                    let recordStatus = self.commandsManager.getResponse(response: recordResponse!, isAudio: false)
                    if (recordStatus != 200) {
                        self.connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, record \(recordStatus)")
                        return
                    }
                    self.streaming = true
                    self.rtpSender.setAudioInfo(sampleRate: self.commandsManager.getSampleRate())

                    self.rtpSender.setSocketInfo(mProtocol: self.commandsManager.mProtocol, socket: self.socket!,
                            videoClientPorts: self.commandsManager.videoClientPorts, audioClientPorts: self.commandsManager.audioClientPorts,
                            videoServerPorts: self.commandsManager.videoServerPorts, audioServerPorts: self.commandsManager.audioServerPorts)
                    self.rtpSender.start()
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
            rtpSender.stop()
            socket?.write(data: commandsManager.createTeardown())
            socket?.disconnect()
            commandsManager.reset()
            streaming = false
            connectCheckerRtsp?.onDisconnectRtsp()
        }
    }
    
    public func sendVideo(frame: Frame) {
        if (streaming && !commandsManager.isOnlyAudio) {
            rtpSender.sendVideo(frame: frame)
        }
    }
    
    public func sendAudio(frame: Frame) {
        if (streaming) {
            rtpSender.sendAudio(frame: frame)
        }
    }
}
