import Foundation

public struct RtpConstants {
    public static var trackAudio = 1
    public static var trackVideo = 0
    public static let clockVideoFrequency = 90000
    public static let rtpHeaderLength = 12
    public static let MTU = 1500
    public static let REPORT_PACKET_LENGTH: UInt64 = 28
    public static let payloadType = 96
    public static let payloadTypeG711 = 8
    //H264
    public static let IDR = 5
    //H265
    public static let CRA_NUT = 21
    public static let IDR_N_LP = 20
    public static let IDR_W_DLP = 19
}
