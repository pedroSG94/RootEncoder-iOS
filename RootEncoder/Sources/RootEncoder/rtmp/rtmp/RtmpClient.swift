//
// Created by Pedro  on 16/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class RtmpClient: SocketCallback {

    private let validSchemes = ["rtmp", "rtmps"]
    private let connectChecker: ConnectChecker
    private var socket: Socket? = nil
    private let commandsManager = RtmpCommandManager()
    private var checkServerAlive = false
    private let rtmpSender: RtmpSender
    var isStreaming = false
    private var publishPermitted = false
    private var tlsEnabled = false
    private var doingRetry = false
    private var numRetry = 0
    private var reTries = 0
    private var url: String? = nil
    private var thread: Task<(), Error>? = nil

    public init(connectChecker: ConnectChecker) {
        self.connectChecker = connectChecker
        rtmpSender = RtmpSender(callback: connectChecker, commandManager: commandsManager)
    }

    public func setAuth(user: String, password: String) {
        commandsManager.setAuth(user: user, password: password)
    }
    
    public func setOnlyAudio(onlyAudio: Bool) {
        commandsManager.audioDisabled = false
        commandsManager.videoDisabled = onlyAudio
    }

    public func setOnlyVideo(onlyVideo: Bool) {
        commandsManager.videoDisabled = false
        commandsManager.audioDisabled = onlyVideo
    }

    public func forceAkamaiTs(enabled: Bool) {
        commandsManager.akamaiTs = enabled
    }

    public func setVideoInfo(sps: [UInt8], pps: [UInt8], vps: [UInt8]?) {
        rtmpSender.setVideoInfo(sps: sps, pps: pps, vps: vps)
    }

    public func setFps(fps: Int) {
        commandsManager.setFps(fps: fps)
    }

    public func setAudioInfo(sampleRate: Int, isStereo: Bool) {
        commandsManager.setAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
        rtmpSender.setAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
    }

    public func setVideoResolution(width: Int, height: Int) {
        commandsManager.setVideoResolution(width: width, height: height)
    }
    
    public func onSocketError(error: String) {
        self.connectChecker.onConnectionFailed(reason: error)
    }

    public func connect(url: String?, isRetry: Bool = false) {
        if (!isRetry) {
            self.doingRetry = true
        }
        if (!self.isStreaming || isRetry) {
            self.isStreaming = true
            thread = Task(priority: .high) {
                guard let url = url else {
                    self.connectChecker.onConnectionFailed(reason: "Endpoint malformed, should be: rtmp://ip:port/appname/streamname")
                    return
                }
                self.url = url
                do {
                    let urlParser = try UrlParser.parse(endpoint: url, requiredProtocols: self.validSchemes)
                    tlsEnabled = urlParser.scheme.hasSuffix("s")
                    commandsManager.host = urlParser.host
                    let defaultPort = if tlsEnabled { 443 } else { 1935 }
                    commandsManager.port = urlParser.port ?? defaultPort
                    commandsManager.appName = urlParser.getAppName()
                    commandsManager.streamName = urlParser.getStreamName()
                    commandsManager.tcUrl = urlParser.getTcUrl()
                    if commandsManager.appName.isEmpty {
                        self.connectChecker.onConnectionFailed(reason: "Endpoint malformed, should be: rtmp://ip:port/appname/streamname")
                        return
                    }
                    
                    if let user = urlParser.authUser, let password = urlParser.authPassword {
                        setAuth(user: user, password: password)
                    }
                    
                    if (try !self.establishConnection()) {
                        self.connectChecker.onConnectionFailed(reason: "Handshake failed")
                        return
                    }
                    guard let socket = self.socket else {
                        throw IOException.runtimeError("Invalid socket, Connection failed")
                    }
                    try commandsManager.sendChunkSize(socket: socket)
                    try commandsManager.sendConnect(auth: "", socket: socket)
                    while (!self.publishPermitted) {
                        try self.handleMessages()
                    }
                    
                    self.handleServerCommands()
                } catch _ as UriParseException {
                    self.connectChecker.onConnectionFailed(reason: "Endpoint malformed, should be: rtmp://ip:port/appname/streamname")
                    return
                } catch {
                    self.connectChecker.onConnectionFailed(reason: "Connection failed: \(error)")
                }
            }
        }
    }

    public func disconnect(clear: Bool = true) {
        if isStreaming {
            rtmpSender.stop(clear: clear)
        }
        let sync = DispatchGroup()
        sync.enter()
        let task = Task {
            do {
                if let socket = self.socket {
                    try self.commandsManager.sendClose(socket: socket)
                }
                sync.leave()
            } catch {
                sync.leave()
            }
        }
        
        let _ = sync.wait(timeout: DispatchTime.now() + 0.1)
        task.cancel()
        closeConnection()
        if (clear) {
            reTries = numRetry
            doingRetry = false
            isStreaming = false
            connectChecker.onDisconnect()
        }
        publishPermitted = false
        thread?.cancel()
        thread = nil
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
        let thread = DispatchQueue(label: "RtmpClientRetry")
        thread.async {
            self.reTries -= 1
            self.disconnect(clear: false)
            Thread.sleep(forTimeInterval: Double(delay / 1000))
            let reconnectUrl = backupUrl == nil ? self.url : backupUrl
            if self.isStreaming {
                self.connect(url: reconnectUrl, isRetry: true)
            }
        }
    }

    private func handleServerCommands() {
        while isStreaming {
            do {
                try handleServerPackets()
            } catch {
            }
        }
    }
    
    private func handleServerPackets() throws {
        while (isStreaming) {
            try handleMessages()
        }
    }

    private func handleMessages() throws {
        guard var socket = socket else {
            throw IOException.runtimeError("Invalid socket, Connection failed")
        }
        let message = try commandsManager.readMessageResponse(socket: socket)
        try commandsManager.checkAndSendAcknowledgement(socket: socket)
        switch message.getType() {
            case .SET_CHUNK_SIZE:
                let setChunkSize = message as! SetChunkSize
                commandsManager.readChunkSize = setChunkSize.chunkSize
                print("chunk size configured to \(setChunkSize.chunkSize)")
            case .ABORT:
                let _ = message as! Abort
            case .ACKNOWLEDGEMENT:
                let _ = message as! Acknowledgement
            case .USER_CONTROL:
                let userControl = message as! UserControl
                if (userControl.type == ControlType.PING_REQUEST) {
                    try commandsManager.sendPong(event: userControl.event, socket: socket)
                } else {
                    print("user control command \(userControl.type) ignored")
                }
            case .WINDOW_ACKNOWLEDGEMENT_SIZE:
                let windowAcknowledgementSize = message as! WindowAcknowledgementSize
                RtmpConfig.acknowledgementWindowSize = windowAcknowledgementSize.acknowledgementWindowSize
            case .SET_PEER_BANDWIDTH:
                let _ = message as! SetPeerBandwidth
                try commandsManager.sendWindowAcknowledgementSize(socket: socket)
            case .COMMAND_AMF0, .COMMAND_AMF3:
                let command = message as! RtmpCommand
                let commandName = commandsManager.sessionHistory.getName(id: command.commandId)
                switch (command.name) {
                    case "_result":
                        switch (commandName) {
                            case "connect":
                                if (commandsManager.onAuth) {
                                    connectChecker.onAuthSuccess()
                                    commandsManager.onAuth = false
                                }
                                try commandsManager.createStream(socket: socket)
                            case "createStream":
                                commandsManager.streamId = Int((command.data[3] as! AmfNumber).value)
                                try commandsManager.sendPublish(socket: socket)
                            default:
                                print("success response received from \(commandName ?? "unknown command")")
                        }
                    case "_error":
                        let description = ((command.data[3] as! AmfObject).getProperty(name: "description") as! AmfString).value
                        switch (commandName) {
                            case "connect":
                                if (description.contains("reason=authfail") || description.contains("reason=nosuchuser")) {
                                    connectChecker.onAuthError()
                                } else if (commandsManager.user != nil && commandsManager.password != nil
                                        && description.contains("challenge=") && description.contains("salt=") //adobe response
                                        || description.contains("nonce="))  { //llnw response
                                    closeConnection()
                                    try _ = establishConnection()
                                    if (self.socket == nil) {
                                        throw IOException.runtimeError("Invalid socket, Connection failed")
                                    } else {
                                        socket = self.socket!
                                    }
                                    commandsManager.onAuth = true
                                    if (description.contains("challenge=") && description.contains("salt=")) { //create adobe auth
                                        let salt = AuthUtil.getSalt(description: description)
                                        let challenge = AuthUtil.getChallenge(description: description)
                                        let opaque = AuthUtil.getOpaque(description: description)
                                        try commandsManager.sendConnect(auth: AuthUtil.getAdobeAuthUserResult(user: commandsManager.user ?? "", password: commandsManager.password ?? "", salt: salt, challenge: challenge, opaque: opaque), socket: socket)
                                    } else if (description.contains("nonce=")) { //create llnw auth
                                        let nonce = AuthUtil.getNonce(description: description)
                                        try commandsManager.sendConnect(auth: AuthUtil.getLlnwAuthUserResult(user: commandsManager.user ?? "", password: commandsManager.password ?? "", nonce: nonce, app: commandsManager.appName), socket: socket)
                                    }
                                } else if (description.contains("code=403")) {
                                    if (description.contains("authmod=adobe")) {
                                        closeConnection()
                                        try _ = establishConnection()
                                        if (self.socket == nil) {
                                            throw IOException.runtimeError("Invalid socket, Connection failed")
                                        } else {
                                            socket = self.socket!
                                        }
                                        print("sending auth mode adobe")
                                        try commandsManager.sendConnect(auth: "?authmod=adobe&user=\(commandsManager.user ?? "")", socket: socket)
                                    } else if (description.contains("authmod=llnw")) {
                                        print("sending auth mode llnw")
                                        try commandsManager.sendConnect(auth: "?authmod=llnw&user=\(commandsManager.user ?? "")", socket: socket)
                                    }
                                } else {
                                    connectChecker.onAuthError()
                                }
                            default:
                                connectChecker.onConnectionFailed(reason: description)
                        }
                    case "onStatus":
                        let code = ((command.data[3] as! AmfObject).getProperty(name: "code") as! AmfString).value
                        switch (code) {
                            case "NetStream.Publish.Start":
                                try commandsManager.sendMetadata(socket: socket)
                                connectChecker.onConnectionSuccess()
                                rtmpSender.socket = socket
                                rtmpSender.start()
                                publishPermitted = true
                            case "NetConnection.Connect.Rejected", "NetStream.Publish.BadName":
                                connectChecker.onConnectionFailed(reason: "onStatus: \(code)")
                            default:
                                print("onStatus $code response received from \(commandName ?? "unknown command")")
                        }
                    default:
                        print("unknown \(command.name) response received from \(commandName ?? "unknown command")")
                }
            case .AGGREGATE:
            _ = message as! Aggregate
            default:
                print("unimplemented response for \(message.getType()). Ignored")
        }
    }

    public func setVideoCodec(codec: VideoCodec) {
        if (!isStreaming) {
            commandsManager.videoCodec = codec
        }
    }
    
    public func setAudioCodec(codec: AudioCodec) {
        if (!isStreaming) {
            commandsManager.audioCodec = codec
        }
    }
    
    private func closeConnection() {
        socket?.disconnect()
        commandsManager.reset()
    }

    public func establishConnection() throws -> Bool {
        socket = Socket(tlsEnabled: tlsEnabled, host: commandsManager.host, port: commandsManager.port, callback: self)
        try socket?.connect()
        let timeStamp = Date().millisecondsSince1970 / 1000
        let handshake = Handshake()
        if (try !handshake.sendHandshake(socket: socket!)) {
            return false
        }
        commandsManager.timestamp = Int(timeStamp)
        commandsManager.startTs = Date().millisecondsSince1970 * 1000
        return true
    }
    
    public func sendVideo(buffer: Array<UInt8>, ts: UInt64) {
        if (isStreaming && !commandsManager.videoDisabled) {
            rtmpSender.sendVideo(buffer: buffer, ts: ts)
        }
    }
    
    public func sendAudio(buffer: Array<UInt8>, ts: UInt64) {
        if (isStreaming && !commandsManager.audioDisabled) {
            rtmpSender.sendAudio(buffer: buffer, ts: ts)
        }
    }
    
    public func setCheckServerAlive(enabled: Bool) {
        checkServerAlive = enabled
    }
    
    public func hasCongestion(percentUsed: Float) -> Bool {
        return rtmpSender.hasCongestion(percentUsed: percentUsed)
    }
    
    public func setLogs(enabled: Bool) {
        rtmpSender.isEnableLogs = enabled
    }
    
    public func resizeCache(newSize: Int) {
        rtmpSender.resizeCache(newSize: newSize)
    }

    public func getCacheSize() -> Int {
        return rtmpSender.getCacheSize()
    }

    public func clearCache() {
        rtmpSender.clearCache()
    }
    
    public func getSentAudioFrames() -> Int {
        return rtmpSender.audioFramesSent
    }

    public func getSentVideoFrames() -> Int {
        return rtmpSender.videoFramesSent
    }

    public func getDroppedAudioFrames() -> Int {
        return rtmpSender.droppedAudioFrames
    }

    public func getDroppedVideoFrames() -> Int {
        return rtmpSender.droppedVideoFrames
    }

    public func resetSentAudioFrames() {
        rtmpSender.audioFramesSent = 0
    }

    public func resetSentVideoFrames() {
        rtmpSender.videoFramesSent = 0
    }

    public func resetDroppedAudioFrames() {
        rtmpSender.droppedAudioFrames = 0
    }

    public func resetDroppedVideoFrames() {
        rtmpSender.droppedVideoFrames = 0
    }
}
