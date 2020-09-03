import Foundation

public struct RtpConstants {
    public static let clockVideoFrequency = 90000
    public static let rtpHeaderLength = 12
    public static let MTU = 1300
    public static let payloadType = 96
    //H264
    public static let IDR = 5
    //H265
    public static let IDR_N_LP = 20
    public static let IDR_W_DLP = 19
}
