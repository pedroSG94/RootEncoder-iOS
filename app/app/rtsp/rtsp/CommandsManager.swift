import Foundation

public class CommandsManager {
    private var host: String?
    private var port: Int?
    private var path: String?
    var mProtocol: Protocol = .TCP
    private var cSeq = 0
    private var sessionId: String? = nil
    private var authorization: String? = nil
    private var timeStamp: Int64?
    var isOnlyAudio = false
    //Audio
    private var sampleRate = 44100
    private var isStereo = true
    //Video
    private var sps: String = "Z0KAHtoHgUZA"
    private var pps: String = "aM4NiA=="
    private var vps: String? = nil
    //Auth
    private var user: String? = nil
    private var password: String? = nil
    //UDP
    var audioClientPorts = [5000, 5001]
    var videoClientPorts = [5002, 5003]
    var audioServerPorts = [5004, 5005]
    var videoServerPorts = [5006, 5007]
    
    public init() {
        let time = Date().millisecondsSince1970
        timeStamp = (time / 1000) << 32 & (((time - ((time / 1000) * 1000)) >> 32) / 1000)
    }
    
    public func getSampleRate() -> Int {
        return sampleRate
    }
    
    private func addHeader() -> String {
        let session = sessionId != nil ? "Session: \(sessionId!)\r\n" : ""
        let auth = authorization != nil ? "Authorization: \(authorization!)\r\n" : ""
        let result = "CSeq: \(cSeq)\r\n\(session)\(auth)\r\n"
        cSeq += 1
        return result
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
        let ports = track == RtpConstants.videoTrack ? videoClientPorts : audioClientPorts
        let params = mProtocol == .TCP ? "TCP;interleaved=\(2 * track)-\(2 * track + 1)" : "UDP;unicast;client_port=\(ports[0])-\(ports[1])"
        return "SETUP rtsp://\(host!):\(port!)\(path!)/trackID=\(track) RTSP/1.0\r\nTransport: RTP/AVP/\(params);mode=record\r\n\(addHeader())"
    }
    
    public func createAnnounce() -> String {
        let body = createBody()
        let result = "ANNOUNCE rtsp://\(host!):\(port!)\(path!) RTSP/1.0\r\nCSeq: \(cSeq)\r\nContent-Length: \(body.utf8.count)\r\nContent-Type: application/sdp\r\n\r\n\(body)"
        cSeq += 1
        return result
    }
    
    public func createAuth(authResponse: String) -> String {
        return ""
    }
    
    public func canAuth() -> Bool {
        return self.user != nil && self.password != nil
    }
    
    public func getAudioTrack() -> Int {
        return RtpConstants.audioTrack
    }
    
    public func getVideoTrack() -> Int {
        return RtpConstants.videoTrack
    }
    
    private func createBody() -> String {
        let body = Body()
        let videoBody = createVideoBody(body: body)
        let audioBody = createAudioBody(body: body)
        return "v=0\r\no=- \(timeStamp!) \(timeStamp!) IN IP4 127.0.0.1\r\ns=Unnamed\r\ni=N/A\r\nc=IN IP4 \(host!)\r\nt=0 0\r\na=recvonly\r\n\(videoBody)\(audioBody)"
    }
    
    private func createAudioBody(body: Body) -> String {
        return body.createAACBody(trackAudio: RtpConstants.audioTrack, sampleRate: sampleRate, isStereo: isStereo)
    }
    
    private func createVideoBody(body: Body) -> String {
        return vps == nil ? body.createH264Body(trackVideo: RtpConstants.videoTrack, sps: sps, pps: pps) : body.createH265Body(trackVideo: RtpConstants.videoTrack, sps: sps, pps: pps, vps: vps!)
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
        if sessionResults.count > 0 {
            sessionId = sessionResults[0][1]
        }
        
        let serverPortsResults = response.groups(for: "server_port=([0-9]+)-([0-9]+)")
        if serverPortsResults.count > 0 {
            if isAudio {
                audioServerPorts[0] = Int(serverPortsResults[0][1])!
                audioServerPorts[1] = Int(serverPortsResults[0][2])!
            } else {
                videoServerPorts[0] = Int(serverPortsResults[0][1])!
                videoServerPorts[1] = Int(serverPortsResults[0][2])!
            }
        }
        let status = getResonseStatus(response: response)
        if status != 200 {
            connectCheckerRtsp?.onConnectionFailedRtsp(reason: "Error configure stream, \(response)")
        }
    }
    
    public func getResonseStatus(response: String) -> Int {
        let statusResults = response.groups(for: "RTSP/\\d.\\d (\\d+) (\\w+)")
        if statusResults.count > 0 {
            let status = Int(statusResults[0][1])!
            return status
        } else {
            return -1
        }
    }
    
    public func reset() {
        cSeq = 0
    }
}
