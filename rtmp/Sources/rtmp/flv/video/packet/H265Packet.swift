//
//  H265Packet.swift
//  rtmp
//
//  Created by Pedro  on 27/3/24.
//

import Foundation

public class H265Packet: BasePacket {
    
    private let TAG = "H265Packet"
    
    private var header = [UInt8](repeating: 0, count: 8)
    private let naluSize = 4
    private var configSend = false
    private var sps: Array<UInt8>? = nil
    private var pps: Array<UInt8>? = nil
    private var vps: Array<UInt8>? = nil
    
    public func setVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>) {
        self.sps = sps
        self.pps = pps
        self.vps = vps
    }
    
    public override func createFlvPacket(buffer: Array<UInt8>, ts: UInt64, callback: (FlvPacket) -> Void) {
        let timeStamp = ts / 1000
        let cts = 0
        let ctsLength = 3
        let codec = VideoFormat.HEVC.rawValue.toUInt32Array()
        header[1] = codec[0]
        header[2] = codec[1]
        header[3] = codec[2]
        header[4] = codec[3]
        
        var packetBuffer = [UInt8]()
        
        if !configSend {
            header[0] = UInt8(0x80 | (Int(VideoDataType.KEYFRAME.rawValue) << 4) | FourCCPacketType.SEQUENCE_START.rawValue)
            
            if let sps = self.sps, let pps = self.pps, let vps = self.vps {
                let config = VideoSpecificConfigHEVC(sps: sps, pps: pps, vps: vps)
                packetBuffer = [UInt8](repeating: 0, count: config.size + header.count - ctsLength)
                config.write(buffer: &packetBuffer, offset: header.count - ctsLength)
            } else {
                print("\(TAG): waiting for a valid sps, pps and vps")
                return
            }
            
            packetBuffer[0..<header.count] = header[0..<header.count]
            callback(FlvPacket(buffer: packetBuffer, timeStamp: Int64(timeStamp), length: packetBuffer.count, type: .VIDEO))
            configSend = true
        }
        
        let headerSize = getHeaderSize(byteBuffer: buffer)
        
        if headerSize == 0 {
            return
        }
        
        let validBuffer = removeHeader(byteBuffer: buffer, size: headerSize)
        let size = validBuffer.count
        packetBuffer = [UInt8](repeating: 0, count: header.count + size + naluSize)
        header[5] = UInt8(cts >> 16)
        header[6] = UInt8(cts >> 8)
        header[7] = UInt8(cts)
        let type: Int = Int(validBuffer[0]) >> (1 & 0x3F)
        var nalType = VideoDataType.INTER_FRAME.rawValue
        
        if type == VideoNalType.IDR_N_LP.rawValue || type == VideoNalType.IDR_W_DLP.rawValue {
            nalType = VideoDataType.KEYFRAME.rawValue
        } else if type == VideoNalType.HEVC_VPS.rawValue || type == VideoNalType.HEVC_SPS.rawValue || type == VideoNalType.HEVC_PPS.rawValue {
            return
        }
        
        header[0] = UInt8(0x80 | Int(nalType) << 4 | FourCCPacketType.CODEC_FRAMES.rawValue)
        writeNaluSize(buffer: &packetBuffer, offset: header.count, size: size)
        
        packetBuffer[header.count + naluSize..<packetBuffer.count] = validBuffer[0..<validBuffer.count]
        packetBuffer[0..<header.count] = header[0..<header.count]
        callback(FlvPacket(buffer: packetBuffer, timeStamp: Int64(timeStamp), length: packetBuffer.count, type: .VIDEO))
    }
    
    private func getHeaderSize(byteBuffer: [UInt8]) -> Int {
        guard let _ = self.sps, let _ = self.pps else {
            return 0
        }
        
        let startCodeSize = getStartCodeSize(byteBuffer: byteBuffer)
        return startCodeSize
    }
    
    private func getStartCodeSize(byteBuffer: [UInt8]) -> Int {
            if byteBuffer[0] == 0x00 && byteBuffer[1] == 0x00
                && byteBuffer[2] == 0x00 && byteBuffer[3] == 0x01 {
                return 4 // match 00 00 00 01
            } else if byteBuffer[0] == 0x00 && byteBuffer[1] == 0x00 && byteBuffer[2] == 0x01 {
                return 3 // match 00 00 01
            }
            return 0
        }
        
    private func writeNaluSize(buffer: inout [UInt8], offset: Int, size: Int) {
        buffer[offset] = UInt8(size >> 24)
        buffer[offset + 1] = UInt8(size >> 16)
        buffer[offset + 2] = UInt8(size >> 8)
        buffer[offset + 3] = UInt8(size & 0xFF)
    }
    
    private func removeHeader(byteBuffer: [UInt8], size: Int = -1) -> [UInt8] {
        let position = (size == -1) ? getStartCodeSize(byteBuffer: byteBuffer) : size
        return Array(byteBuffer[position..<byteBuffer.count])
    }
    
    public override func reset(resetInfo: Bool = true) {
        if resetInfo {
            sps = nil
            pps = nil
        }
        configSend = false
    }
}
