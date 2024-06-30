//
//  H264FlvPacket.swift
//  app
//
//  Created by Pedro  on 19/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import Foundation

public class RtmpH264Packet: RtmpBasePacket {
    
    private let TAG = "H264Packet"

    private var header = [UInt8](repeating: 0, count: 5)
    private let naluSize = 4
    private var configSend = false
    private var sps: Array<UInt8>? = nil
    private var pps: Array<UInt8>? = nil
    
    enum VideoType: UInt8 {
        case SEQUENCE = 0x00
        case NALU = 0x01
        case EO_SEQ = 0x02
    }
    
    func setVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>) {
        self.sps = sps
        self.pps = pps
    }
    
    public override func createFlvPacket(buffer: Array<UInt8>, ts: UInt64, callback: (FlvPacket) -> Void) {
        let timeStamp = ts / 1000
        let cts = 0
        header[2] = UInt8(cts >> 16)
        header[3] = UInt8(cts >> 8)
        header[4] = UInt8(cts)
        
        var packetBuffer = [UInt8]()
        
        if !configSend {
            header[0] = UInt8((Int(VideoDataType.KEYFRAME.rawValue) << 4) | VideoFormat.AVC.rawValue)
            header[1] = VideoType.SEQUENCE.rawValue
            
            if let sps = self.sps, let pps = self.pps {
                let config = VideoSpecificConfigAVC(sps: sps, pps: pps)
                packetBuffer = [UInt8](repeating: 0, count: config.size + header.count)
                config.write(buffer: &packetBuffer, offset: header.count)
            } else {
                print("\(TAG): waiting for a valid sps and pps")
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
        if size > UInt32.max {
            return
        }
        packetBuffer = [UInt8](repeating: 0, count: header.count + size + naluSize)
        
        let type: Int = Int(validBuffer[0]) & 0x1F
        var nalType = VideoDataType.INTER_FRAME.rawValue
        
        if type == VideoNalType.IDR.rawValue {
            nalType = VideoDataType.KEYFRAME.rawValue
        } else if type == VideoNalType.SPS.rawValue || type == VideoNalType.PPS.rawValue {
            return
        }
        
        header[0] = UInt8((Int(nalType) << 4) | VideoFormat.AVC.rawValue)
        header[1] = VideoType.NALU.rawValue
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
