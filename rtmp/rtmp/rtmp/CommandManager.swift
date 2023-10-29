//
// Created by Pedro  on 16/7/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class CommandManager {

    let sessionHistory = CommandSessionHistory()
    var timestamp = 0
    private var commandId = 0
    var streamId = 0
    var host = ""
    var port = 1935
    var appName = ""
    var streamName = ""
    var tcUrl = ""
    var user: String? = nil
    var password: String? = nil
    var onAuth = false
    var akamaiTs = false
    var startTs: Int64 = 0
    var readChunkSize = RtmpConfig.DEFAULT_CHUNK_SIZE
    var audioDisabled = false
    var videoDisabled = false
    private let writeSync = DispatchQueue(label: "com.pedro.rtmp.CommandManager")

    private var width = 640
    private var height = 480
    private var fps = 30
    private var sampleRate = 44100
    private var isStereo = true
    private var bytesRead = 0
    private var acknowledgementSequence = 0

    public func setVideoResolution(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    public func setFps(fps: Int) {
        self.fps = fps
    }

    public func setAudioInfo(sampleRate: Int, isStereo: Bool) {
        self.sampleRate = sampleRate
        self.isStereo = isStereo
    }

    public func setAuth(user: String?, password: String?) {
        self.user = user
        self.password = password
    }

    private func getCurrentTimestamp() -> Int {
        Int(Date().millisecondsSince1970) / 1000 - timestamp
    }

    public func sendChunkSize(socket: Socket) async throws {
        if (RtmpConfig.writeChunkSize != RtmpConfig.DEFAULT_CHUNK_SIZE) {
            let chunkSize = SetChunkSize(chunkSize: RtmpConfig.writeChunkSize)
            chunkSize.header.timeStamp = getCurrentTimestamp()
            chunkSize.header.messageStreamId = streamId
            try await chunkSize.writeHeader(socket: socket)
            try await chunkSize.writeBody(socket: socket)
        } else {
            print("using default write chunk size \(RtmpConfig.writeChunkSize)")
        }
    }

    func checkAndSendAcknowledgement(socket: Socket) async throws {
        if (bytesRead >= RtmpConfig.acknowledgementWindowSize) {
            acknowledgementSequence += bytesRead
            bytesRead -= RtmpConfig.acknowledgementWindowSize
            let acknowledgement = Acknowledgement(sequenceNUmber: acknowledgementSequence)
            try await acknowledgement.writeHeader(socket: socket)
            try await acknowledgement.writeBody(socket: socket)
            print("send \(acknowledgement)")
        }
    }
    
    public func sendConnect(auth: String, socket: Socket) async throws {
        commandId += 1
        let connect = CommandAmf0(name: "connect", commandId: commandId, timeStamp: getCurrentTimestamp(), streamId: streamId,
                basicHeader: BasicHeader(chunkType: ChunkType.TYPE_0, chunkStreamId: Int(ChunkStreamId.OVER_CONNECTION.rawValue)))
        let connectInfo = AmfObject()
        connectInfo.setProperty(name: "app", data: appName + auth)
        connectInfo.setProperty(name: "flashVer", data: "FMLE/3.0 (compatible; Lavf57.56.101)")
        connectInfo.setProperty(name: "swfUrl", data: "")
        connectInfo.setProperty(name: "tcUrl", data: tcUrl + auth)
        connectInfo.setProperty(name: "fpad", data: false)
        connectInfo.setProperty(name: "capabilities", data: 239)
        if (!audioDisabled) {
            connectInfo.setProperty(name: "audioCodecs", data: 3191)
        }
        if (!videoDisabled) {
            connectInfo.setProperty(name: "videoCodecs", data: 252)
            connectInfo.setProperty(name: "videoFunction", data: 1)
        }
        connectInfo.setProperty(name: "pageUrl", data: "")
        connectInfo.setProperty(name: "objectEncoding", data: 0)
        connect.addData(amfData: connectInfo)
        try await connect.writeHeader(socket: socket)
        try await connect.writeBody(socket: socket)
        sessionHistory.setPacket(id: commandId, name: "connect")
        print("send connect: \(connect)")
    }

    public func createStream(socket: Socket) async throws {
        commandId += 1
        let releaseStream = CommandAmf0(name: "releaseStream", commandId: commandId, timeStamp: getCurrentTimestamp(), streamId: streamId,
                basicHeader: BasicHeader(chunkType: ChunkType.TYPE_0, chunkStreamId: Int(ChunkStreamId.OVER_CONNECTION.rawValue)))
        releaseStream.addData(amfData: AmfNull())
        releaseStream.addData(amfData: AmfString(value: streamName))

        try await releaseStream.writeHeader(socket: socket)
        try await releaseStream.writeBody(socket: socket)
        sessionHistory.setPacket(id: commandId, name: "releaseStream")

        commandId += 1
        let fcPublish = CommandAmf0(name: "FCPublish", commandId: commandId, timeStamp: getCurrentTimestamp(), streamId: streamId,
                basicHeader: BasicHeader(chunkType: ChunkType.TYPE_0, chunkStreamId: Int(ChunkStreamId.OVER_CONNECTION.rawValue)))
        fcPublish.addData(amfData: AmfNull())
        fcPublish.addData(amfData: AmfString(value: streamName))

        try await fcPublish.writeHeader(socket: socket)
        try await fcPublish.writeBody(socket: socket)
        sessionHistory.setPacket(id: commandId, name: "FCPublish")

        commandId += 1
        let createStream = CommandAmf0(name: "createStream", commandId: commandId, timeStamp: getCurrentTimestamp(), streamId: streamId,
                basicHeader: BasicHeader(chunkType: ChunkType.TYPE_0, chunkStreamId: Int(ChunkStreamId.OVER_CONNECTION.rawValue)))
        createStream.addData(amfData: AmfNull())

        try await createStream.writeHeader(socket: socket)
        try await createStream.writeBody(socket: socket)
        sessionHistory.setPacket(id: commandId, name: "createStream")
        print("send createStream")
    }

    public func readMessageResponse(socket: Socket) async throws -> RtmpMessage {
        let message = try await RtmpMessage.getMessage(socket: socket, chunkSize: readChunkSize, commandSessionHistory: sessionHistory)
        sessionHistory.setReadHeader(header: message.header)
        print("read message: \(message)")
        bytesRead += message.header.getPacketLength()
        return message
    }

    public func sendMetadata(socket: Socket) async throws {
        let metadata = DataAmf0(name: "@setDataFrame", timeStamp: getCurrentTimestamp(), streamId: streamId)
        metadata.addData(amfData: AmfString(value: "onMetaData"))
        let amfEcmaArray = AmfEcmaArray()
        amfEcmaArray.setProperty(name: "duration", data: 0.0)
        if (!videoDisabled) {
            amfEcmaArray.setProperty(name: "width", data: Double(width))
            amfEcmaArray.setProperty(name: "height", data: Double(height))
            amfEcmaArray.setProperty(name: "videocodecid", data: 7.0)
            amfEcmaArray.setProperty(name: "framerate", data: Double(fps))
            amfEcmaArray.setProperty(name: "videodatarate", data: 0.0)
        }
        if (!audioDisabled) {
            amfEcmaArray.setProperty(name: "audiocodecid", data: 10.0)
            amfEcmaArray.setProperty(name: "audiosamplerate", data: Double(sampleRate))
            amfEcmaArray.setProperty(name: "audiosamplesize", data: 16.0)
            amfEcmaArray.setProperty(name: "audiodatarate", data: 0.0)
            amfEcmaArray.setProperty(name: "stereo", data: isStereo)
        }
        amfEcmaArray.setProperty(name: "filesize", data: 0.0)
        metadata.addData(amfData: amfEcmaArray)

        try await metadata.writeHeader(socket: socket)
        try await metadata.writeBody(socket: socket)
    }

    public func sendPublish(socket: Socket) async throws {
        commandId += 1
        let closeStream = CommandAmf0(name: "publish", commandId: commandId, timeStamp: getCurrentTimestamp(), streamId: streamId,
                basicHeader: BasicHeader(chunkType: ChunkType.TYPE_0, chunkStreamId: Int(ChunkStreamId.OVER_STREAM.rawValue)))
        closeStream.addData(amfData: AmfNull())
        closeStream.addData(amfData: AmfString(value: streamName))
        closeStream.addData(amfData: AmfString(value: "live"))

        try await closeStream.writeHeader(socket: socket)
        try await closeStream.writeBody(socket: socket)
        sessionHistory.setPacket(id: commandId, name: "publish")
    }

    public func sendWindowAcknowledgementSize(socket: Socket) async throws {
        let windowAcknowledgementSize = WindowAcknowledgementSize(acknowledgementWindowSize: RtmpConfig.acknowledgementWindowSize, timeStamp: getCurrentTimestamp())
        try await windowAcknowledgementSize.writeHeader(socket: socket)
        try await windowAcknowledgementSize.writeBody(socket: socket)
        print("send windowAcknowledgementSize: \(windowAcknowledgementSize.description)")
    }

    public func sendPong(event: Event, socket: Socket) async throws {
        let pong = UserControl(type: ControlType.PONG_REPLY, event: event)
        try await pong.writeHeader(socket: socket)
        try await pong.writeBody(socket: socket)
    }

    public func sendClose(socket: Socket) async throws {
        commandId += 1
        let closeStream = CommandAmf0(name: "closeStream", commandId: commandId, timeStamp: getCurrentTimestamp(), streamId: streamId,
                basicHeader: BasicHeader(chunkType: ChunkType.TYPE_0, chunkStreamId: Int(ChunkStreamId.OVER_STREAM.rawValue)))
        closeStream.addData(amfData: AmfNull())

        try await closeStream.writeHeader(socket: socket)
        try await closeStream.writeBody(socket: socket)
        sessionHistory.setPacket(id: commandId, name: "closeStream")
    }

    public func sendVideoPacket(flvPacket: FlvPacket, socket: Socket) async throws -> Int {
        let video: Video
        if (akamaiTs) {
            var packet = flvPacket
            packet.timeStamp = ((Date().millisecondsSince1970 * 1000) - startTs) / 1000
            video = Video(flvPacket: packet, streamId: streamId)
        } else {
            video = Video(flvPacket: flvPacket, streamId: streamId)
        }
        try await video.writeHeader(socket: socket)
        try await video.writeBody(socket: socket)
        return video.header.getPacketLength()
    }

    public func sendAudioPacket(flvPacket: FlvPacket, socket: Socket) async throws -> Int {
        let audio: Audio
        if (akamaiTs) {
            var packet = flvPacket
            packet.timeStamp = ((Date().millisecondsSince1970 * 1000) - startTs) / 1000
            audio = Audio(flvPacket: packet, streamId: streamId)
        } else {
            audio = Audio(flvPacket: flvPacket, streamId: streamId)
        }
        try await audio.writeHeader(socket: socket)
        try await audio.writeBody(socket: socket)
        return audio.header.getPacketLength()
    }

    public func reset() {
        startTs = 0
        timestamp = 0
        streamId = 0
        commandId = 0
        readChunkSize = RtmpConfig.DEFAULT_CHUNK_SIZE
        sessionHistory.reset()
        acknowledgementSequence = 0
        bytesRead = 0
    }
}
