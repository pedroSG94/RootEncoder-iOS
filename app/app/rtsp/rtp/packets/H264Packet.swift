import Foundation

public class H264Packet: BasePacket {
    
    private var callback: VideoPacketCallback?
    private var sendKeyFrame = false
    private var stapA: Array<UInt8>?
    
    public init(sps: Array<UInt8>, pps: Array<UInt8>, videoPacketCallback: VideoPacketCallback) {
        super.init(clock: UInt64(RtpConstants.clockVideoFrequency), payloadType: RtpConstants.payloadType + RtpConstants.audioTrack)
        callback = videoPacketCallback
        channelIdentifier = RtpConstants.videoTrack
        setSpsPps(sps: sps, pps: pps)
    }
    
    public func createAndSendPacket(data: Frame) {
        var buffer = data.buffer!
        let ts = data.timeStamp!
        let dts = ts * 1000
        var frame = RtpFrame()
        frame.channelIdentifier = channelIdentifier
        frame.rtpPort = rtpPort
        frame.rtcpPort = rtcpPort
        
        var header = Array<UInt8>(repeating: 0, count: 5)
        buffer = buffer.get(destiny: &header, index: 0, length: 5)

        let naluLength = Int(buffer.count)
        let type: UInt8 = header[4] & 0x1F

        if type == RtpConstants.IDR {
            var rtpBuffer = getBuffer(size: stapA!.count + RtpConstants.rtpHeaderLength)
            let rtpTs = updateTimeStamp(buffer: &rtpBuffer, timeStamp: dts)
            markPacket(buffer: &rtpBuffer)
            rtpBuffer[RtpConstants.rtpHeaderLength...RtpConstants.rtpHeaderLength + stapA!.count - 1] = stapA![0...stapA!.count - 1]
            updateSeq(buffer: &rtpBuffer)
            
            frame.timeStamp = rtpTs
            frame.length = rtpBuffer.count
            frame.buffer = rtpBuffer
            callback?.onVideoFrameCreated(rtpFrame: frame)
            sendKeyFrame = true
        }
        if sendKeyFrame {
            // Small NAL unit => Single NAL unit
            if (naluLength <= maxPacketSize - RtpConstants.rtpHeaderLength - 1) {
                var rtpBuffer = getBuffer(size: naluLength + RtpConstants.rtpHeaderLength + 1)
                rtpBuffer[RtpConstants.rtpHeaderLength] = header[4]
                
                buffer = buffer.get(destiny: &rtpBuffer, index: RtpConstants.rtpHeaderLength + 1, length: naluLength)
                
                let rtpTs = updateTimeStamp(buffer: &rtpBuffer, timeStamp: dts)
                markPacket(buffer: &rtpBuffer)
                updateSeq(buffer: &rtpBuffer)
                
                frame.timeStamp = rtpTs
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
                
                var sum = 0
                while sum < naluLength {
                    var length = 0
                    if (naluLength - sum > maxPacketSize - RtpConstants.rtpHeaderLength - 2) {
                        length = maxPacketSize - RtpConstants.rtpHeaderLength - 2
                    } else {
                        length = buffer.count
                    }
                    var rtpBuffer = getBuffer(size: length + RtpConstants.rtpHeaderLength + 2)
                    rtpBuffer[RtpConstants.rtpHeaderLength] = header[0]
                    rtpBuffer[RtpConstants.rtpHeaderLength + 1] = header[1]

                    let rtpTs = updateTimeStamp(buffer: &rtpBuffer, timeStamp: dts)
                    
                    buffer = buffer.get(destiny: &rtpBuffer, index: RtpConstants.rtpHeaderLength + 2, length: length)
                    
                    sum += length
                    if sum >= naluLength {
                        rtpBuffer[RtpConstants.rtpHeaderLength + 1] += 0x40
                        markPacket(buffer: &rtpBuffer)
                    }
                    updateSeq(buffer: &rtpBuffer)

                    frame.timeStamp = rtpTs
                    frame.length = rtpBuffer.count
                    frame.buffer = rtpBuffer
                    callback?.onVideoFrameCreated(rtpFrame: frame)
                    // Switch start bit
                    header[1] = header[1] & 0x7F
                }
            }
        }
    }
    
    private func setSpsPps(sps: Array<UInt8>, pps: Array<UInt8>) {
        let spsBuffer = sps
        let ppsBuffer = pps
        stapA = Array<UInt8>(repeating: 0, count: spsBuffer.count + ppsBuffer.count + 5)
        
        // STAP-A NAL header is 24
        stapA![0] = 0x18
        // Write NALU 1 size into the array (NALU 1 is the SPS).
        stapA![1] = UInt8(spsBuffer.count) >> 0x08
        stapA![2] = UInt8(ppsBuffer.count) & 0xFF
        // Write NALU 2 size into the array (NALU 2 is the PPS).
        stapA![spsBuffer.count + 3] = UInt8(ppsBuffer.count) >> 0x08
        stapA![spsBuffer.count + 4] = UInt8(ppsBuffer.count) & 0xFF
        
        // Write NALU 1 into the array, then write NALU 2 into the array.
        stapA![3...spsBuffer.count - 1 + 3] = spsBuffer[0...spsBuffer.count - 1]
        stapA![5 + spsBuffer.count...5 + spsBuffer.count + ppsBuffer.count - 1] = ppsBuffer[0...ppsBuffer.count - 1]
    }
    
    override public func reset() {
        super.reset()
        sendKeyFrame = false
    }
}
