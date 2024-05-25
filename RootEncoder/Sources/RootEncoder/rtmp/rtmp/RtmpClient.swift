//
// Created by Pedro  on 16/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class RtmpClient {

    private let connectChecker: ConnectChecker
    private var socket: Socket? = nil
    private let commandManager = RtmpCommandManager()
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
        rtmpSender = RtmpSender(callback: connectChecker, commandManager: commandManager)
    }

    public func setAuth(user: String, password: String) {
        commandManager.setAuth(user: user, password: password)
    }
    
    public func setOnlyAudio(onlyAudio: Bool) {
        commandManager.audioDisabled = false
        commandManager.videoDisabled = onlyAudio
    }

    public func setOnlyVideo(onlyVideo: Bool) {
        commandManager.videoDisabled = false
        commandManager.audioDisabled = onlyVideo
    }

    public func forceAkamaiTs(enabled: Bool) {
        commandManager.akamaiTs = enabled
    }

    public func setVideoInfo(sps: [UInt8], pps: [UInt8], vps: [UInt8]?) {
        rtmpSender.setVideoInfo(sps: sps, pps: pps, vps: vps)
    }

    public func setFps(fps: Int) {
        commandManager.setFps(fps: fps)
    }

    public func setAudioInfo(sampleRate: Int, isStereo: Bool) {
        commandManager.setAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
        rtmpSender.setAudioInfo(sampleRate: sampleRate, isStereo: isStereo)
    }

    public func setVideoResolution(width: Int, height: Int) {
        commandManager.setVideoResolution(width: width, height: height)
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
                let urlResults = url.groups(for: "^rtmps?://([^/:]+)(?::(\\d+))*/([^/]+)/?([^*]*)$")
                if urlResults.count > 0 {
                    let groups = urlResults[0]
                    self.tlsEnabled = groups[0].hasPrefix("rtmps")
                    let host = groups[1]
                    let defaultPort = groups.count == 3
                    let port = defaultPort ? self.tlsEnabled ? 443 : 1935 : Int(groups[2]) ?? 1935
                    let _ = "/\(groups[defaultPort ? 2 : 3])/\(groups[defaultPort ? 3 : 4])" //path
                    self.commandManager.host = host
                    self.commandManager.port = port
                    self.commandManager.appName = self.getAppName(app: groups[3], name: groups[4])
                    self.commandManager.streamName = self.getStreamName(name: groups[4])
                    let tcUrlIndex = groups[0].index(groups[0].startIndex, offsetBy: groups[0].count - self.commandManager.streamName.count)
                    self.commandManager.tcUrl = self.getTcUrl(url: String(groups[0].prefix(upTo: tcUrlIndex)))
                    do {
                        if (try await !self.establishConnection()) {
                            self.connectChecker.onConnectionFailed(reason: "Handshake failed")
                            return
                        }
                        guard let socket = self.socket else {
                            throw IOException.runtimeError("Invalid socket, Connection failed")
                        }
                        try await self.commandManager.sendChunkSize(socket: socket)
                        try await self.commandManager.sendConnect(auth: "", socket: socket)
                        while (!self.publishPermitted) {
                            try await self.handleMessages()
                        }
                        
                        await self.handleServerCommands()
                    } catch {
                        self.connectChecker.onConnectionFailed(reason: "Connection failed: \(error)")
                    }
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
                    try await self.commandManager.sendClose(socket: socket)
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
            self.connect(url: reconnectUrl, isRetry: true)
        }
    }
    
    private func getAppName(app: String, name: String) -> String {
        if (!name.contains("/")) {
            return app
        } else {
            return "\(app)/\(String(name.prefix(upTo: name.firstIndex(of: "/")!)))"
        }
    }

    private func getStreamName(name: String) -> String {
        if (!name.contains("/")) {
            return name
        } else {
            let index = name.index(name.firstIndex(of: "/")!, offsetBy: 1)
            return String(name[name.startIndex..<index])
        }
    }

    private func getTcUrl(url: String) -> String {
        if (url.hasSuffix("/")) {
            return String(url.dropLast(1))
        } else {
            return url
        }
    }

    private func handleServerCommands() async {
        do {
            try await handleServerPackets()
        } catch {
            
        }
    }
    
    private func handleServerPackets() async throws {
        while (isStreaming) {
            try await handleMessages()
        }
    }

    private func handleMessages() async throws {
        guard var socket = socket else {
            throw IOException.runtimeError("Invalid socket, Connection failed")
        }
        let message = try await commandManager.readMessageResponse(socket: socket)
        try await commandManager.checkAndSendAcknowledgement(socket: socket)
        switch message.getType() {
            case .SET_CHUNK_SIZE:
                let setChunkSize = message as! SetChunkSize
                commandManager.readChunkSize = setChunkSize.chunkSize
                print("chunk size configured to \(setChunkSize.chunkSize)")
            case .ABORT:
                let _ = message as! Abort
            case .ACKNOWLEDGEMENT:
                let _ = message as! Acknowledgement
            case .USER_CONTROL:
                let userControl = message as! UserControl
                if (userControl.type == ControlType.PING_REQUEST) {
                    try await commandManager.sendPong(event: userControl.event, socket: socket)
                } else {
                    print("user control command \(userControl.type) ignored")
                }
            case .WINDOW_ACKNOWLEDGEMENT_SIZE:
                let windowAcknowledgementSize = message as! WindowAcknowledgementSize
                RtmpConfig.acknowledgementWindowSize = windowAcknowledgementSize.acknowledgementWindowSize
            case .SET_PEER_BANDWIDTH:
                let _ = message as! SetPeerBandwidth
                try await commandManager.sendWindowAcknowledgementSize(socket: socket)
            case .COMMAND_AMF0, .COMMAND_AMF3:
                let command = message as! RtmpCommand
                let commandName = commandManager.sessionHistory.getName(id: command.commandId)
                switch (command.name) {
                    case "_result":
                        switch (commandName) {
                            case "connect":
                                if (commandManager.onAuth) {
                                    connectChecker.onAuthSuccess()
                                    commandManager.onAuth = false
                                }
                                try await commandManager.createStream(socket: socket)
                            case "createStream":
                                commandManager.streamId = Int((command.data[3] as! AmfNumber).value)
                                try await commandManager.sendPublish(socket: socket)
                            default:
                                print("success response received from \(commandName ?? "unknown command")")
                        }
                    case "_error":
                        let description = ((command.data[3] as! AmfObject).getProperty(name: "description") as! AmfString).value
                        switch (commandName) {
                            case "connect":
                                if (description.contains("reason=authfail") || description.contains("reason=nosuchuser")) {
                                    connectChecker.onAuthError()
                                } else if (commandManager.user != nil && commandManager.password != nil
                                        && description.contains("challenge=") && description.contains("salt=") //adobe response
                                        || description.contains("nonce="))  { //llnw response
                                    closeConnection()
                                    try _ = await establishConnection()
                                    if (self.socket == nil) {
                                        throw IOException.runtimeError("Invalid socket, Connection failed")
                                    } else {
                                        socket = self.socket!
                                    }
                                    commandManager.onAuth = true
                                    if (description.contains("challenge=") && description.contains("salt=")) { //create adobe auth
                                        let salt = AuthUtil.getSalt(description: description)
                                        let challenge = AuthUtil.getChallenge(description: description)
                                        let opaque = AuthUtil.getOpaque(description: description)
                                        try await commandManager.sendConnect(auth: AuthUtil.getAdobeAuthUserResult(user: commandManager.user ?? "", password: commandManager.password ?? "", salt: salt, challenge: challenge, opaque: opaque), socket: socket)
                                    } else if (description.contains("nonce=")) { //create llnw auth
                                        let nonce = AuthUtil.getNonce(description: description)
                                        try await commandManager.sendConnect(auth: AuthUtil.getLlnwAuthUserResult(user: commandManager.user ?? "", password: commandManager.password ?? "", nonce: nonce, app: commandManager.appName), socket: socket)
                                    }
                                } else if (description.contains("code=403")) {
                                    if (description.contains("authmod=adobe")) {
                                        closeConnection()
                                        try _ = await establishConnection()
                                        if (self.socket == nil) {
                                            throw IOException.runtimeError("Invalid socket, Connection failed")
                                        } else {
                                            socket = self.socket!
                                        }
                                        print("sending auth mode adobe")
                                        try await commandManager.sendConnect(auth: "?authmod=adobe&user=\(commandManager.user ?? "")", socket: socket)
                                    } else if (description.contains("authmod=llnw")) {
                                        print("sending auth mode llnw")
                                        try await commandManager.sendConnect(auth: "?authmod=llnw&user=\(commandManager.user ?? "")", socket: socket)
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
                                try await commandManager.sendMetadata(socket: socket)
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
            commandManager.videoCodec = codec
        }
    }
    
    public func setAudioCodec(codec: AudioCodec) {
        if (!isStreaming) {
            commandManager.audioCodec = codec
        }
    }
    
    private func closeConnection() {
        socket?.disconnect()
        commandManager.reset()
    }

    public func establishConnection() async throws -> Bool {
        socket = Socket(tlsEnabled: tlsEnabled, host: commandManager.host, port: commandManager.port)
        try await socket?.connect()
        let timeStamp = Date().millisecondsSince1970 / 1000
        let handshake = Handshake()
        if (try await !handshake.sendHandshake(socket: socket!)) {
            return false
        }
        commandManager.timestamp = Int(timeStamp)
        commandManager.startTs = Date().millisecondsSince1970 * 1000
        return true
    }
    
    public func sendVideo(buffer: Array<UInt8>, ts: UInt64) {
        if (isStreaming && !commandManager.videoDisabled) {
            rtmpSender.sendVideo(buffer: buffer, ts: ts)
        }
    }
    
    public func sendAudio(buffer: Array<UInt8>, ts: UInt64) {
        if (isStreaming && !commandManager.audioDisabled) {
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
