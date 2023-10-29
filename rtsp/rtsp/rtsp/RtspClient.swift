import Foundation

public class RtspClient {
    
    private var socket: Socket?
    private let connectCheckerRtsp: ConnectCheckerRtsp
    private var streaming = false
    private let commandsManager = CommandsManager()
    private var tlsEnabled = false
    private let rtspSender: RtspSender
    private var semaphore = DispatchSemaphore(value: 0)
    private var checkServerAlive = false
    private var doingRetry = false
    private var numRetry = 0
    private var reTries = 0
    private var url: String? = nil
    
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

    /**
    * Must be called before connect
    */
    public func setOnlyAudio(onlyAudio: Bool) {
        if (onlyAudio) {
          RtpConstants.trackAudio = 0
          RtpConstants.trackVideo = 1
        } else {
          RtpConstants.trackVideo = 0
          RtpConstants.trackAudio = 1
        }
        commandsManager.audioDisabled = false
        commandsManager.videoDisabled = onlyAudio
    }

    /**
    * Must be called before connect
    */
    public func setOnlyVideo(onlyVideo: Bool) {
        RtpConstants.trackVideo = 0
        RtpConstants.trackAudio = 1
        commandsManager.videoDisabled = false
        commandsManager.audioDisabled = onlyVideo
    }

    public func setAudioInfo(sampleRate: Int, isStereo: Bool) {
        commandsManager.setAudioConfig(sampleRate: sampleRate, isStereo: isStereo)
    }
    
    public func setVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        commandsManager.setVideoConfig(sps: sps, pps: pps, vps: vps)
        semaphore.signal()
    }
    
    public func connect(url: String?, isRetry: Bool = false) {
        if (!isRetry) {
            self.doingRetry = true
        }
        if (!self.streaming || isRetry) {
            self.streaming = true
            let thread = DispatchQueue(label: "RtspClient")
            thread.async {
                guard let url = url else {
                    self.connectCheckerRtsp.onConnectionFailedRtsp(reason: "Endpoint malformed, should be: rtsp://ip:port/appname/streamname")
                    return
                }
                self.url = url
                let urlResults = url.groups(for: "^rtsps?://([^/:]+)(?::(\\d+))*/([^/]+)/?([^*]*)$")
                if urlResults.count > 0 {
                    let groups = urlResults[0]
                    self.tlsEnabled = groups[0].hasPrefix("rtsps")
                    let host = groups[1]
                    let defaultPort = groups.count == 3
                    let port = defaultPort ? 554 : Int(groups[2]) ?? 554
                    let path = "/\(groups[defaultPort ? 2 : 3])/\(groups[defaultPort ? 3 : 4])"
                    self.commandsManager.setUrl(host: host, port: port, path: path)
                    do {
                        self.socket = Socket(tlsEnabled: self.tlsEnabled, host: host, port: port)
                        try self.socket?.connect()
                        if (!self.commandsManager.audioDisabled) {
                            self.rtspSender.setAudioInfo(sampleRate: self.commandsManager.getSampleRate())
                        }
                        if (!self.commandsManager.videoDisabled) {
                            if (self.commandsManager.sps == nil || self.commandsManager.pps == nil) {
                                print("waiting for sps and pps")
                                let _ = self.semaphore.wait(timeout: DispatchTime.now() + 5)
                                if (self.commandsManager.sps == nil || self.commandsManager.pps == nil) {
                                    self.connectCheckerRtsp.onConnectionFailedRtsp(reason: "sps or pps is null")
                                    return
                                } else {
                                    self.rtspSender.setVideoInfo(sps: self.commandsManager.sps!, pps: self.commandsManager.pps!, vps: self.commandsManager.vps)
                                }
                            } else {
                                self.rtspSender.setVideoInfo(sps: self.commandsManager.sps!, pps: self.commandsManager.pps!, vps: self.commandsManager.vps)
                            }
                        }
                        //Options
                        try self.socket?.write(data: self.commandsManager.createOptions())
                        let _ = try self.commandsManager.getResponse(socket: self.socket!, method: Method.OPTIONS)

                        //Announce
                        try self.socket?.write(data: self.commandsManager.createAnnounce())
                        let announceResponse = try self.commandsManager.getResponse(socket: self.socket!, method: Method.ANNOUNCE)
                        if announceResponse.status == 403 {
                            self.connectCheckerRtsp.onConnectionFailedRtsp(reason: "Error configure stream, access denied")
                        } else if announceResponse.status == 401 {
                            if (self.commandsManager.canAuth()) {
                                //Announce with auth
                                try self.socket?.write(data: self.commandsManager.createAnnounceWithAuth(authResponse: announceResponse.text))
                                let authResponse = try self.commandsManager.getResponse(socket: self.socket!, method: Method.ANNOUNCE)
                                if authResponse.status == 401 {
                                    self.connectCheckerRtsp.onAuthErrorRtsp()
                                } else if authResponse.status == 200 {
                                    self.connectCheckerRtsp.onAuthSuccessRtsp()
                                } else {
                                    self.connectCheckerRtsp.onConnectionFailedRtsp(reason: "Error configure stream, announce with auth failed \(authResponse.status)")
                                }
                            } else {
                                self.connectCheckerRtsp.onAuthErrorRtsp()
                                return
                            }
                        } else if announceResponse.status != 200 {
                            self.connectCheckerRtsp.onConnectionFailedRtsp(reason: "Error configure stream, announce with auth failed \(announceResponse.status)")
                        }
                        if !self.commandsManager.videoDisabled {
                            //Setup video
                            try self.socket?.write(data: self.commandsManager.createSetup(track: self.commandsManager.getVideoTrack()))
                            let setupVideoStatus = try self.commandsManager.getResponse(socket: self.socket!, method: Method.SETUP).status
                            if (setupVideoStatus != 200) {
                                self.connectCheckerRtsp.onConnectionFailedRtsp(reason: "Error configure stream, setup video \(setupVideoStatus)")
                                return
                            }
                        }
                        if !self.commandsManager.audioDisabled {
                            //Setup audio
                            try self.socket?.write(data: self.commandsManager.createSetup(track: self.commandsManager.getAudioTrack()))
                            let setupAudioStatus = try self.commandsManager.getResponse(socket: self.socket!, method: Method.SETUP).status
                            if (setupAudioStatus != 200) {
                                self.connectCheckerRtsp.onConnectionFailedRtsp(reason: "Error configure stream, setup audio \(setupAudioStatus)")
                                return
                            }
                        }
                        //Record
                        try self.socket?.write(data: self.commandsManager.createRecord())
                        let recordStatus = try self.commandsManager.getResponse(socket: self.socket!, method: Method.RECORD).status
                        if (recordStatus != 200) {
                            self.connectCheckerRtsp.onConnectionFailedRtsp(reason: "Error configure stream, record \(recordStatus)")
                            return
                        }

                        self.rtspSender.setSocketInfo(mProtocol: self.commandsManager.mProtocol, socket: self.socket!,
                                videoClientPorts: self.commandsManager.videoClientPorts, audioClientPorts: self.commandsManager.audioClientPorts,
                                videoServerPorts: self.commandsManager.videoServerPorts, audioServerPorts: self.commandsManager.audioServerPorts)
                        self.rtspSender.start()
                        self.connectCheckerRtsp.onConnectionSuccessRtsp()
                        
                        self.handleServerCommands()
                    } catch let error {
                        self.connectCheckerRtsp.onConnectionFailedRtsp(reason: error.localizedDescription)
                        return
                    }
                } else {
                    self.connectCheckerRtsp.onConnectionFailedRtsp(reason: "Endpoint malformed, should be: rtsp://ip:port/appname/streamname")
                    return
                }
            }
        }
    }
    
    private func handleServerCommands() {
        //Read and print server commands received each 2 seconds
        while (streaming) {
            guard let socket = socket else {
                return
            }
            do {
                let _ = try commandsManager.getResponse(socket: socket)
                //Do something depend of command if required
            } catch {
            }
        }
      }
    
    public func isStreaming() -> Bool {
        streaming
    }
    
    public func disconnect(clear: Bool = true) {
        let thread = DispatchQueue(label: "RtspClient.disconnect")
        if streaming {
            rtspSender.stop()
        }
        let sync = DispatchGroup()
        sync.enter()
        thread.async {
            do {
                try self.socket?.write(data: self.commandsManager.createTeardown())
                sync.leave()
            } catch {
                sync.leave()
            }
        }
        let _ = sync.wait(timeout: DispatchTime.now() + 0.1)
        socket?.disconnect()
        if (clear) {
            commandsManager.clear()
            reTries = numRetry
            doingRetry = false
            streaming = false
            connectCheckerRtsp.onDisconnectRtsp()
        } else {
            commandsManager.retryClear()
        }
    }
    
    public func sendVideo(buffer: Array<UInt8>, ts: UInt64) {
        if (!commandsManager.videoDisabled) {
            rtspSender.sendVideo(buffer: buffer, ts: ts)
        }
    }
    
    public func sendAudio(buffer: Array<UInt8>, ts: UInt64) {
        if (!commandsManager.audioDisabled) {
            rtspSender.sendAudio(buffer: buffer, ts: ts)
        }
    }
    
    public func setRetries(reTries: Int) {
        numRetry = reTries
        self.reTries = reTries
    }
    
    public func shouldRetry(reason: String) -> Bool {
        let validReason = doingRetry && !reason.contains("Endpoint malformed")
        return validReason && reTries > 0
    }
    
    public func reconnect(delay: Int, backupUrl: String? = nil) {
        let thread = DispatchQueue(label: "RtspClientRetry")
        thread.async {
            self.reTries -= 1
            self.disconnect(clear: false)
            Thread.sleep(forTimeInterval: Double(delay / 1000))
            let reconnectUrl = backupUrl == nil ? self.url : backupUrl
            self.connect(url: reconnectUrl, isRetry: true)
        }
    }
    
    public func setCheckServerAlive(enabled: Bool) {
        checkServerAlive = enabled
    }
    
    public func hasCongestion(percentUsed: Float) -> Bool {
        return rtspSender.hasCongestion(percentUsed: percentUsed)
    }
    
    public func setLogs(enabled: Bool) {
        rtspSender.isEnableLogs = enabled
    }
    
    public func resizeCache(newSize: Int) {
        rtspSender.resizeCache(newSize: newSize)
    }

    public func getCacheSize() -> Int {
        return rtspSender.getCacheSize()
    }

    public func clearCache() {
        rtspSender.clearCache()
    }
    
    public func getSentAudioFrames() -> Int {
        return rtspSender.audioFramesSent
    }

    public func getSentVideoFrames() -> Int {
        return rtspSender.videoFramesSent
    }

    public func getDroppedAudioFrames() -> Int {
        return rtspSender.droppedAudioFrames
    }

    public func getDroppedVideoFrames() -> Int {
        return rtspSender.droppedVideoFrames
    }

    public func resetSentAudioFrames() {
        rtspSender.audioFramesSent = 0
    }

    public func resetSentVideoFrames() {
        rtspSender.videoFramesSent = 0
    }

    public func resetDroppedAudioFrames() {
        rtspSender.droppedAudioFrames = 0
    }

    public func resetDroppedVideoFrames() {
        rtspSender.droppedVideoFrames = 0
    }
}
