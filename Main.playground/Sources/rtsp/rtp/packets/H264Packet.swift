import Foundation

public class H264Packet: BasePacket {
    
    private var callback: VideoPacketCallback?
    private var sendKeyFrame = false
    private var stapA: Array<UInt8>?
    
    public init(sps: String, pps: String, videoPacketCallback: VideoPacketCallback) {
        super.init(clock: Int64(RtpConstants.clockVideoFrequency))
        self.callback = videoPacketCallback
        self.channelIdentifier = 0x02
        self.stapA = setSpsPps(sps: sps, pps: pps)
    }
    
    public func createAndSendPacket(buffer: Array<UInt8>, ts: Int64) {
        var frame = RtpFrame()
        frame.timeStamp = ts
        frame.channelIdentifier = self.channelIdentifier
        frame.rtpPort = self.rtpPort
        frame.rtcpPort = self.rtcpPort
        
        var header = buffer[0...5]
        let naluLength = buffer.count + 1
        let type = header[4] & 0x1F
        if type == RtpConstants.IDR {
            var rtpBuffer = self.getBuffer(size: stapA!.count + RtpConstants.rtpHeaderLength)
            self.updateTimeStamp(buffer: &rtpBuffer, timeStamp: ts)
            self.markPacket(buffer: &rtpBuffer)
            rtpBuffer[RtpConstants.rtpHeaderLength...rtpBuffer.count] = stapA![0...stapA!.count]
            self.updateSeq(buffer: &rtpBuffer)
            
            frame.length = rtpBuffer.count
            frame.buffer = rtpBuffer
            callback?.onVideoFrameCreated(rtpFrame: frame)
            self.sendKeyFrame = true
        }
        if sendKeyFrame {
            // Small NAL unit => Single NAL unit
            if (naluLength <= self.maxPacketSize - RtpConstants.rtpHeaderLength - 2) {
                let length = naluLength
                
                var rtpBuffer = self.getBuffer(size: length + RtpConstants.rtpHeaderLength)
                rtpBuffer[RtpConstants.rtpHeaderLength] = header[4]
                
                rtpBuffer[RtpConstants.rtpHeaderLength + 1...rtpBuffer.count] = buffer[0...buffer.count]
                
                self.updateTimeStamp(buffer: &rtpBuffer, timeStamp: ts)
                self.markPacket(buffer: &rtpBuffer)
                self.updateSeq(buffer: &rtpBuffer)
                
                frame.length = rtpBuffer.count
                frame.buffer = rtpBuffer
                callback?.onVideoFrameCreated(rtpFrame: frame)
            }
            // Large NAL unit => Split nal unit
            else {
                // Set FU-A header
                header[1] = header[4] & 0x1F
                header[1] += 0x80 // set start bit to 1
                // Set FU-A indicator
                header[0] = ((header[4] & 0x60) & 0xFF) // FU indicator NRI
                header[0] += 28
                
                var sum = 1
                while sum < naluLength {
                    let cont = ((naluLength - sum) > (maxPacketSize - RtpConstants.rtpHeaderLength - 2)) ?
                        (maxPacketSize - RtpConstants.rtpHeaderLength - 2) : (naluLength - sum)
                    let length = cont
                    
                    var rtpBuffer = self.getBuffer(size: length + RtpConstants.rtpHeaderLength + 1)
                    
                    rtpBuffer[RtpConstants.rtpHeaderLength] = header[0]
                    rtpBuffer[RtpConstants.rtpHeaderLength + 1] = header[1]
                    
                    self.updateTimeStamp(buffer: &rtpBuffer, timeStamp: ts)
                    
                    rtpBuffer[RtpConstants.rtpHeaderLength + 2...rtpBuffer.count] = buffer[0...buffer.count]
                    
                    sum += length
                    if sum >= naluLength {
                        rtpBuffer[RtpConstants.rtpHeaderLength + 1] += 0x40
                        self.markPacket(buffer: &rtpBuffer)
                    }
                    self.updateSeq(buffer: &rtpBuffer)
                    
                    frame.length = rtpBuffer.count
                    frame.buffer = rtpBuffer
                    callback?.onVideoFrameCreated(rtpFrame: frame)
                    // Switch start bit
                    header[1] = header[1] & 0x7F
                }
            }
        }
    }
    
    private func setSpsPps(sps: String, pps: String) -> Array<UInt8> {
        let spsBuffer = [UInt8](sps.utf8)
        let ppsBuffer = [UInt8](pps.utf8)
        stapA = Array<UInt8>(repeating: 0, count: spsBuffer.count + ppsBuffer.count + 5)
        
        // STAP-A NAL header is 24
        stapA![0] = UInt8(24)
        // Write NALU 1 size into the array (NALU 1 is the SPS).
        stapA![1] = spsBuffer.count >> UInt8(8)
        stapA![2] = ppsBuffer.count & 0xFF
        // Write NALU 2 size into the array (NALU 2 is the PPS).
        stapA![spsBuffer.count + 3] = ppsBuffer.count >> UInt8(8)
        stapA![spsBuffer.count + 4] = ppsBuffer.count & 0xFF
        
        // Write NALU 1 into the array, then write NALU 2 into the array.
        stapA![3...spsBuffer.count + 3] = spsBuffer[0...spsBuffer.count]
        stapA![5 + spsBuffer.count...5 + spsBuffer.count + ppsBuffer.count] = ppsBuffer[0...ppsBuffer.count]
    }
    
    override public func reset() {
        super.reset()
        sendKeyFrame = false
    }
}
