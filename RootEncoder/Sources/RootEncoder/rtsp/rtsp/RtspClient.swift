import Foundation

public class RtspClient: SocketCallback {
    
    private var socket: Socket?
    private let connectChecker: ConnectChecker
    private var streaming = false
    private let commandsManager = RtspCommandManager()
    private var tlsEnabled = false
    private let rtspSender: RtspSender
    private var checkServerAlive = false
    private var doingRetry = false
    private var numRetry = 0
    private var reTries = 0
    private var url: String? = nil
    private var semaphore: Task<Bool, Error>? = nil
    private var thread: Task<(), Error>? = nil
    
    public init(connectChecker: ConnectChecker) {
        self.connectChecker = connectChecker
        rtspSender = RtspSender(callback: connectChecker, commandsManager: commandsManager)
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
        semaphore?.cancel()
    }
    
    public func onSocketError(error: String) {
        self.connectChecker.onConnectionFailed(reason: error)
    }
    
    public func connect(url: String?, isRetry: Bool = false) {
        if (!isRetry) {
            self.doingRetry = true
        }
        if (!self.streaming || isRetry) {
            self.streaming = true
            thread = Task(priority: .high) {
                guard let url = url else {
                    self.connectChecker.onConnectionFailed(reason: "Endpoint malformed, should be: rtsp://ip:port/appname/streamname")
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
                    let streamName = groups[defaultPort ? 3 : 4].isEmpty ? "" : "/\(groups[defaultPort ? 3 : 4])"
                    let path = "/\(groups[defaultPort ? 2 : 3])" + streamName
                    self.commandsManager.setUrl(host: host, port: port, path: path)
                    do {
                        self.socket = Socket(tlsEnabled: self.tlsEnabled, host: host, port: port, callback: self)
                        try self.socket?.connect()
                        if (!self.commandsManager.audioDisabled) {
                            self.rtspSender.setAudioInfo(sampleRate: self.commandsManager.getSampleRate())
                        }
                        if (!self.commandsManager.videoDisabled) {
                            if (!self.commandsManager.videoInfoReady()) {
                                print("waiting for sps and pps")
                                semaphore = Task {
                                    try await Task.sleep(nanoseconds: 5 * 1_000_000_000)
                                    return true
                                }
                                let _ = await semaphore?.result
                                if (!self.commandsManager.videoInfoReady()) {
                                    self.connectChecker.onConnectionFailed(reason: "sps or pps is null")
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
                        socket?.flush()
                        let _ = try self.commandsManager.getResponse(socket: self.socket!, method: Method.OPTIONS)

                        //Announce
                        try self.socket?.write(data: self.commandsManager.createAnnounce())
                        socket?.flush()
                        let announceResponse = try self.commandsManager.getResponse(socket: self.socket!, method: Method.ANNOUNCE)
                        if announceResponse.status == 403 {
                            self.connectChecker.onConnectionFailed(reason: "Error configure stream, access denied")
                        } else if announceResponse.status == 401 {
                            if (self.commandsManager.canAuth()) {
                                //Announce with auth
                                try self.socket?.write(data: self.commandsManager.createAnnounceWithAuth(authResponse: announceResponse.text))
                                socket?.flush()
                                let authResponse = try self.commandsManager.getResponse(socket: self.socket!, method: Method.ANNOUNCE)
                                if authResponse.status == 401 {
                                    self.connectChecker.onAuthError()
                                } else if authResponse.status == 200 {
                                    self.connectChecker.onAuthSuccess()
                                } else {
                                    self.connectChecker.onConnectionFailed(reason: "Error configure stream, announce with auth failed \(authResponse.status)")
                                }
                            } else {
                                self.connectChecker.onAuthError()
                                return
                            }
                        } else if announceResponse.status != 200 {
                            self.connectChecker.onConnectionFailed(reason: "Error configure stream, announce with auth failed \(announceResponse.status)")
                        }
                        if !self.commandsManager.videoDisabled {
                            //Setup video
                            try self.socket?.write(data: self.commandsManager.createSetup(track: self.commandsManager.getVideoTrack()))
                            socket?.flush()
                            let setupVideoStatus = try self.commandsManager.getResponse(socket: self.socket!, method: Method.SETUP).status
                            if (setupVideoStatus != 200) {
                                self.connectChecker.onConnectionFailed(reason: "Error configure stream, setup video \(setupVideoStatus)")
                                return
                            }
                        }
                        if !self.commandsManager.audioDisabled {
                            //Setup audio
                            try self.socket?.write(data: self.commandsManager.createSetup(track: self.commandsManager.getAudioTrack()))
                            socket?.flush()
                            let setupAudioStatus = try self.commandsManager.getResponse(socket: self.socket!, method: Method.SETUP).status
                            if (setupAudioStatus != 200) {
                                self.connectChecker.onConnectionFailed(reason: "Error configure stream, setup audio \(setupAudioStatus)")
                                return
                            }
                        }
                        //Record
                        try self.socket?.write(data: self.commandsManager.createRecord())
                        socket?.flush()
                        let recordStatus = try self.commandsManager.getResponse(socket: self.socket!, method: Method.RECORD).status
                        if (recordStatus != 200) {
                            self.connectChecker.onConnectionFailed(reason: "Error configure stream, record \(recordStatus)")
                            return
                        }

                        self.rtspSender.setSocketInfo(mProtocol: self.commandsManager.mProtocol, socket: self.socket!,
                                videoClientPorts: self.commandsManager.videoClientPorts, audioClientPorts: self.commandsManager.audioClientPorts,
                                videoServerPorts: self.commandsManager.videoServerPorts, audioServerPorts: self.commandsManager.audioServerPorts)
                        self.rtspSender.start()
                        self.connectChecker.onConnectionSuccess()
                        
                        self.handleServerCommands()
                    } catch let error {
                        self.connectChecker.onConnectionFailed(reason: error.localizedDescription)
                        return
                    }
                } else {
                    self.connectChecker.onConnectionFailed(reason: "Endpoint malformed, should be: rtsp://ip:port/appname/streamname")
                    return
                }
            }
        }
    }
    
    private func handleServerCommands() {
        //Read and print server commands received
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
        if streaming {
            rtspSender.stop()
        }
        let sync = DispatchGroup()
        sync.enter()
        let task = Task {
            do {
                try self.socket?.write(data: self.commandsManager.createTeardown())
                sync.leave()
            } catch {
                sync.leave()
            }
        }
        let _ = sync.wait(timeout: DispatchTime.now() + 0.1)
        task.cancel()
        socket?.disconnect()
        if (clear) {
            commandsManager.clear()
            reTries = numRetry
            doingRetry = false
            streaming = false
            connectChecker.onDisconnect()
        } else {
            commandsManager.retryClear()
        }
        thread?.cancel()
        thread = nil
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
    
    public func setVideoCodec(codec: VideoCodec) {
        if (!streaming) {
            commandsManager.videoCodec = codec
        }
    }
    
    public func setAudioCodec(codec: AudioCodec) {
        if (!streaming) {
            commandsManager.audioCodec = codec
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
            if self.streaming {
                self.connect(url: reconnectUrl, isRetry: true)
            }
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
