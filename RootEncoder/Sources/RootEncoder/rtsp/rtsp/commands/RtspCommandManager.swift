import Foundation

public class RtspCommandManager {
    private var host: String?
    private var port: Int?
    private var path: String?
    var mProtocol: Protocol = .TCP
    private var cSeq = 0
    private var sessionId: String? = nil
    private var authorization: String? = nil
    private var timeStamp: Int64?
    var videoDisabled = false
    var audioDisabled = false
    //Audio
    private var sampleRate = 44100
    private var isStereo = true
    //Video
    var sps: Array<UInt8>? = nil
    var pps: Array<UInt8>? = nil
    var vps: Array<UInt8>? = nil
    //Auth
    private var user: String? = nil
    private var password: String? = nil
    //UDP
    var audioClientPorts = [5000, 5001]
    var videoClientPorts = [5002, 5003]
    var audioServerPorts = [5004, 5005]
    var videoServerPorts = [5006, 5007]
    private let commandParser = CommandParser()
    var videoCodec = VideoCodec.H264
    var audioCodec = AudioCodec.AAC
    
    public init() {
        let time = Date().millisecondsSince1970
        timeStamp = (time / 1000) << 32 & (((time - ((time / 1000) * 1000)) >> 32) / 1000)
    }
    
    public func videoInfoReady() -> Bool {
      switch videoCodec {
      case VideoCodec.H264:
          return sps != nil && pps != nil
      case VideoCodec.H265:
          return sps != nil && pps != nil && vps != nil
      }
    }
    
    public func getSampleRate() -> Int {
        sampleRate
    }
    
    private func addHeader() -> String {
        let session = sessionId?.isEmpty ?? true != true ? "Session: \(sessionId!)\r\n" : ""
        let auth = authorization?.isEmpty ?? true != true ? "Authorization: \(authorization!)\r\n" : ""
        let result = "CSeq: \(cSeq)\r\n\(session)\(auth)"
        cSeq += 1
        return result
    }
    
    public func createOptions() -> String {
        let options = "OPTIONS rtsp://\(host!):\(port!)\(path!) RTSP/1.0\r\n\(addHeader())\r\n"
        print(options)
        return options
    }
    
    public func createRecord() -> String {
        let record = "RECORD rtsp://\(host!):\(port!)\(path!) RTSP/1.0\r\nRange: npt=0.000-\r\n\(addHeader())\r\n"
        print(record)
        return record
    }
    
    public func createTeardown() -> String {
        let teardown = "TEARDOWN rtsp://\(host!):\(port!)\(path!) RTSP/1.0\r\n\(addHeader())\r\n"
        print(teardown)
        return teardown
    }
    
    public func createSetup(track: Int) -> String {
        let ports = track == RtpConstants.trackVideo ? videoClientPorts : audioClientPorts
        let params = mProtocol == .TCP ? "TCP;unicast;interleaved=\(2 * track)-\(2 * track + 1)" : "UDP;unicast;client_port=\(ports[0])-\(ports[1])"
        let setup = "SETUP rtsp://\(host!):\(port!)\(path!)/streamid=\(track) RTSP/1.0\r\nTransport: RTP/AVP/\(params);mode=record\r\n\(addHeader())\r\n"
        print(setup)
        return setup
    }
    
    public func createAnnounce() -> String {
        let body = createBody()
        let result = "ANNOUNCE rtsp://\(host!):\(port!)\(path!) RTSP/1.0\r\n\(addHeader())Content-Length: \(body.utf8.count)\r\nContent-Type: application/sdp\r\n\r\n\(body)"
        cSeq += 1
        print(result)
        return result
    }

    public func createAnnounceWithAuth(authResponse: String) -> String {
        authorization = createAuth(authResponse: authResponse)
        return createAnnounce()
    }

    private func createAuth(authResponse: String) -> String {
        let authPattern = authResponse.groups(for: "realm=\"(.+)\",\\s+nonce=\"(\\w+)\"")
        if authPattern.count > 0 {
            print("using digest auth")
            let realm = authPattern[0][1]
            let nonce = authPattern[0][2]
            let hash1 = "\(user!):\(realm):\(password!)".md5
            let hash2 = "ANNOUNCE:rtsp://\(host!):\(port!)\(path!)".md5
            let hash3 = "\(hash1):\(nonce):\(hash2)".md5
            return "Digest username=\"\(user!)\", realm=\"\(realm)\", nonce=\"\(nonce)\", uri=\"rtsp://\(host!):\(port!)\(path!)\", response=\"\(hash3)\""
        } else {
            print("using basic auth")
            let data = "\(user!):\(password!)"
            let base64Data = data.data(using: .utf8)!.base64EncodedString()
            return "Basic \(base64Data)"
        }
    }
    
    public func canAuth() -> Bool {
        user != nil && password != nil
    }
    
    public func getAudioTrack() -> Int {
        RtpConstants.trackAudio
    }
    
    public func getVideoTrack() -> Int {
        RtpConstants.trackVideo
    }
    
    private func createBody() -> String {
        let body = SdpBody()
        var videoBody = ""
        if (!videoDisabled) {
            videoBody = createVideoBody(body: body)
        }
        var audioBody = ""
        if (!audioDisabled) {
            audioBody = createAudioBody(body: body)
        }
        return "v=0\r\no=- \(timeStamp!) \(timeStamp!) IN IP4 127.0.0.1\r\ns=Unnamed\r\ni=N/A\r\nc=IN IP4 \(host!)\r\nt=0 0\r\na=recvonly\r\n\(videoBody)\(audioBody)"
    }
    
    private func createAudioBody(body: SdpBody) -> String {
        return switch audioCodec {
        case .AAC:
            body.createAACBody(trackAudio: RtpConstants.trackAudio, sampleRate: sampleRate, isStereo: isStereo)
        case .G711:
            body.createG711Body(trackAudio: RtpConstants.trackAudio, sampleRate: sampleRate, isStereo: isStereo)
        }
    }
    
    private func createVideoBody(body: SdpBody) -> String {
        let spsString = Data(sps!).base64EncodedString()
        let ppsString = Data(pps!).base64EncodedString()
        let vpsString = vps != nil ? Data(vps!).base64EncodedString() : nil
        return switch videoCodec {
        case .H264:
            body.createH264Body(trackVideo: RtpConstants.trackVideo, sps: spsString, pps: ppsString)
        case .H265:
            body.createH265Body(trackVideo: RtpConstants.trackVideo, sps: spsString, pps: ppsString, vps: vpsString!)
        }
    }
    
    public func setAuth(user: String, password: String) {
        self.user = user
        self.password = password
    }
    
    public func setUrl(host: String, port: Int, path: String) {
        self.host = host
        self.port = port
        self.path = path
    }
    
    public func setAudioConfig(sampleRate: Int, isStereo: Bool) {
        self.sampleRate = sampleRate
        self.isStereo = isStereo
    }
    
    public func setVideoConfig(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) {
        self.sps = sps
        self.pps = pps
        self.vps = vps
    }
    
    public func getResponse(socket: Socket, method: Method = Method.UNKNOWN) throws -> RtspCommand {
        let response = try socket.readString()
        print(response)
        if (method == Method.UNKNOWN) {
            return commandParser.parseCommand(commandText: response)
        } else {
            let command = commandParser.parseResponse(method: method, responseText: response)
            sessionId = commandParser.getSessionId(command: command)
            if (command.method == Method.SETUP && mProtocol == Protocol.UDP) {
                _ = commandParser.loadServerPorts(command: command, protocol: mProtocol, audioClientPorts: audioClientPorts, videoClientPorts: videoClientPorts, audioServerPorts: &audioServerPorts, videoServerPorts: &videoServerPorts)
            }
            return command
        }
    }
    
    public func clear() {
      sps = nil
      pps = nil
      vps = nil
      retryClear()
    }

    public func retryClear() {
      cSeq = 0
      sessionId = nil
    }
}
