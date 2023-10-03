import Foundation

public class SdpBody {
    
    private let audioSamplesRates = [
        96000, // 0
        88200, // 1
        64000, // 2
        48000, // 3
        44100, // 4
        32000, // 5
        24000, // 6
        22050, // 7
        16000, // 8
        12000, // 9
        11025, // 10
        8000,  // 11
        7350,  // 12
        -1,   // 13
        -1,   // 14
        -1   // 15
    ]
    
    public func createAACBody(trackAudio: Int, sampleRate: Int, isStereo: Bool) -> String {
        let sampleNum = audioSamplesRates.firstIndex(of: sampleRate)
        let channel = isStereo ? 2 : 1
        let config = (2 & 0x1F) << 11 | (sampleNum! & 0x0F) << 7 | (channel & 0x0F) << 3
        let hexStringConfig = String(format:"%02X", config)
        let payload = RtpConstants.payloadType + trackAudio
        return "m=audio 0 RTP/AVP \(payload)\r\na=rtpmap:\(payload) MPEG4-GENERIC/\(sampleRate)/\(channel)\r\na=fmtp:\(payload) streamtype=5; profile-level-id=15; mode=AAC-hbr; config=\(hexStringConfig); SizeLength=13; IndexLength=3; IndexDeltaLength=3;\r\na=control:trackID=\(trackAudio)\r\n"
    }
    
    public func createH264Body(trackVideo: Int, sps: String, pps: String) -> String {
        let payload = RtpConstants.payloadType + trackVideo
        return "m=video 0 RTP/AVP \(payload)\r\na=rtpmap:\(payload) H264/\(RtpConstants.clockVideoFrequency)\r\na=fmtp:\(payload) packetization-mode=1;sprop-parameter-sets=\(sps),\(pps);\r\na=control:trackID=\(trackVideo)\r\n"
    }
    
    public func createH265Body(trackVideo: Int, sps: String, pps: String, vps: String) -> String {
        let payload = RtpConstants.payloadType + trackVideo
        return "m=video 0 RTP/AVP \(payload)\r\na=rtpmap:\(payload) H265/\(RtpConstants.clockVideoFrequency)\r\na=fmtp:\(payload) sprop-sps=\(sps); sprop-pps=\(pps); sprop-vps=\(vps);\r\na=control:trackID=\(trackVideo)\r\n"
    }
}
