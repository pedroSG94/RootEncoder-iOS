import Foundation

public class CommandsManager {
    private var host: String?
    private var port: Int?
    private var path: String?
    private var mProtocol: Protocol = .TCP
    private var cSeq = 0
    private var sessionId: String? = nil
    private var authorization: String? = nil
    private var trackAudio = 0
    private var trackVideo = 1
    private var timeStamp: Int64?
    //Audio
    private var sampleRate = 44100
    private var isStereo = true
    //Video
    private var sps: String = ""
    private var pps: String = ""
    private var vps: String? = nil
    //Auth
    private var user: String? = nil
    private var password: String? = nil
    //UDP
    private let audioClientPorts = [5000, 5001]
    private let videoClientPorts = [5002, 5003]
    private var audioServerPorts = [5004, 5005]
    private var videoServerPorts = [5006, 5007]
    
    public init() {
        let time = Date().millisecondsSince1970
        timeStamp = (time / 1000) << 32 & (((time - ((time / 1000) * 1000)) >> 32) / 1000)
    }
    
    private func addHeader() -> String {
        let session = sessionId != nil ? "Session: \(sessionId as Optional)\r\n" : ""
        let auth = authorization != nil ? "Authorization: \(authorization as Optional)\r\n" : ""
        cSeq += 1
        return "CSeq: \(cSeq)\r\n\(session)\(auth)\r\n"
    }
    
    public func createOptions() -> String {
        return "OPTIONS rtsp://\(host!):\(port!)\(path!) RTSP/1.0\r\n\(addHeader())"
    }
    
    public func createRecord() -> String {
        return "RECORD rtsp://\(host!):\(port!)\(path!) RTSP/1.0\r\nRange: npt=0.000-\r\n\(addHeader())"
    }
    
    public func createTeardown() -> String {
        return "TEARDOWN rtsp://\(host!):\(port!)\(path!) RTSP/1.0\r\n\(addHeader())"
    }
    
    public func createSetup(track: Int) -> String {
        let ports = track == trackVideo ? videoClientPorts : audioClientPorts
        let params = mProtocol == .TCP ? "TCP;interleaved=\(2 * track)-\(2 * track + 1)" : "UDP;unicast;client_port=\(ports[0])-\(ports[1])"
        return "SETUP rtsp://\(host!):\(port!)\(path!)/trackID=\(track) RTSP/1.0\r\nTransport: RTP/AVP/\(params);mode=record\r\n\(addHeader())"
    }
    
    public func createAnnounce() -> String {
        let body = createBody()
        return "ANNOUNCE rtsp://\(host!):\(port!)\(path!) RTSP/1.0\r\nCSeq: \(cSeq += 1)\r\nContent-Length: \(body.count)\r\nContent-Type: application/sdp\r\n\r\n\(body)"
    }
    
    public func createAuth(authResponse: String) -> String {
        return ""
    }
    
    public func canAuth() -> Bool {
        return self.user != nil && self.password != nil
    }
    
    public func getAudioTrack() -> Int {
       return trackAudio
    }
    
    public func getVideoTrack() -> Int {
        return trackVideo
    }
    
    private func createBody() -> String {
        let body = Body()
        let videoBody = createVideoBody(body: body)
        let audioBody = createAudioBody(body: body)
        return "v=0\r\no=- \(timeStamp!) \(timeStamp!) IN IP4 127.0.0.1\r\ns=Unnamed\r\ni=N/A\r\nc=IN IP4 \(host!)\r\nt=0 0\r\na=recvonly\r\n\(videoBody)\(audioBody)"
    }
    
    private func createAudioBody(body: Body) -> String {
        return body.createAACBody(trackAudio: trackAudio, sampleRate: sampleRate, isStereo: isStereo)
    }
    
    private func createVideoBody(body: Body) -> String {
        return vps == nil ? body.createH264Body(trackVideo: trackVideo, sps: sps, pps: pps) : body.createH265Body(trackVideo: trackVideo, sps: sps, pps: pps, vps: vps!)
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
    
    public func setVideoConfig(sps: String, pps: String, vps: String?) {
        self.sps = sps
        self.pps = pps
        self.vps = vps
    }
    
    public func getResponse(response: String, isAudio: Bool, connectCheckerRtsp: ConnectCheckerRtsp?) {
        let sessionResults = response.groups(for: "Session: (\\w+)")
        print("session")
        if sessionResults.count > 0 {
            self.sessionId = sessionResults[0][0]
            print("sessionId ok: \(sessionId)")
        }
        print("session 2")
        let serverPortsResults = response.groups(for: "server_port=([0-9]+)-([0-9]+)")
        print("ports")
        if serverPortsResults.count > 0 {
            if isAudio {
                self.audioServerPorts[0] = Int(serverPortsResults[0][0])!
                self.audioServerPorts[1] = Int(serverPortsResults[0][1])!
            } else {
                print("ports ok")
                self.videoServerPorts[0] = Int(serverPortsResults[0][0])!
                self.videoServerPorts[1] = Int(serverPortsResults[0][1])!
            }
        }
        print("ports 2")
        let status = getResonseStatus(response: response)
        print("status: \(status)")
        if status != 200 {
            connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, \(response)")
        }
    }
    
    public func getResonseStatus(response: String) -> Int {
        let statusResults = response.groups(for: "RTSP/\\d.\\d (\\d+) (\\w+)")
        if statusResults.count > 0 {
            let status = Int(statusResults[0][0])!
            print("status: \(status)")
            return status
        } else {
            return -1
        }
    }
    
    public func reset() {
        cSeq = 0
    }
}
