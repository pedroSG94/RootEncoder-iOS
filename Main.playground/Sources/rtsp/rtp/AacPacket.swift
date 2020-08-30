import Foundation


public class AacPacket: BasePacket {
    
    private var callback: AudioPacketCallback?
    
    init(sampleRate: Int, audioPacketCallback: AudioPacketCallback) {
        super.init(clock: Int64(sampleRate))
        self.channelIdentifier = 0x00
        self.callback = audioPacketCallback
    }
    
    public func createAndSendPacket(buffer: Array<UInt8>, ts: Int64) {
        let frame = RtpFrame()
        callback?.onAudioFrameCreated(rtpFrame: frame)
    }
}
