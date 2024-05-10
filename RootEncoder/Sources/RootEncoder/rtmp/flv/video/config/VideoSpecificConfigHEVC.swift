//
//  VideoSpecificConfigHEVC.swift
//  rtmp
//
//  Created by Pedro  on 24/3/24.
//

import Foundation

class VideoSpecificConfigHEVC {
    
    private let sps: Array<UInt8>
    private let pps: Array<UInt8>
    private let vps: Array<UInt8>
    private(set) public var size = 0
    
    init(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>) {
        self.sps = sps
        self.pps = pps
        self.vps = vps
        self.size = calculateSize(sps: sps, pps: pps, vps: vps)
        
    }
    
    func write(buffer: inout Array<UInt8>, offset: Int) {
        var data = Array<UInt8>()
        let configurationVersion = 1
        data.append(UInt8(configurationVersion))
        
        let spsParser = SpsH265Parser()
        spsParser.parse(sps: sps)
        let combined = UInt8((spsParser.generalProfileSpace << 6) | (spsParser.generalTierFlag << 5) | spsParser.generalProfileIdc)
        data.append(combined)
        
        data.append(contentsOf: spsParser.generalProfileCompatibilityFlags.toUInt32Array())
        
        data.append(contentsOf: spsParser.generalConstraintIndicatorFlags.toUInt48Array())
        
        data.append(UInt8(spsParser.generalLevelIdc))

        let minSpatialSegmentationIdc = 0
        data.append(contentsOf: (0xf000 | minSpatialSegmentationIdc).toUInt16Array())
        let parallelismType = 0
        data.append(UInt8(0xfc | parallelismType))
        data.append(UInt8(0xfc | spsParser.chromaFormat))
        data.append(UInt8(0xf8 | spsParser.bitDepthLumaMinus8))
        data.append(UInt8(0xf8 | spsParser.bitDepthChromaMinus8))
        let avgFrameRate = 0
        data.append(contentsOf: avgFrameRate.toUInt16Array())
        
        let constantFrameRate = 0
        let numTemporalLayers = 0
        let temporalIdNested = 0
        let lengthSizeMinusOne = 3
        
        let combined2 = (constantFrameRate << 6) | (numTemporalLayers << 3) | (temporalIdNested << 2) | lengthSizeMinusOne
        
        data.append(UInt8(combined2))
        
        data.append(0x03)
        
        writeNaluArray(type: 0x20, naluByteBuffer: vps, buffer: &data)
        writeNaluArray(type: 0x21, naluByteBuffer: sps, buffer: &data)
        writeNaluArray(type: 0x22, naluByteBuffer: pps, buffer: &data)
        
        buffer.insert(contentsOf: data, at: offset)
    }
    
    private func writeNaluArray(type: UInt8, naluByteBuffer: Array<UInt8>, buffer: inout Array<UInt8>) {
        let arrayCompleteness = 1
        let reserved = 0
        buffer.append(UInt8((arrayCompleteness << 7) | (reserved << 6) | Int(type)))
        let numNalus = 1
        buffer.append(contentsOf: numNalus.toUInt16Array())
        buffer.append(contentsOf: naluByteBuffer.count.toUInt16Array())
        buffer.append(contentsOf: naluByteBuffer)
    }
    
    private func calculateSize(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>) -> Int {
        return 23 + 5 + vps.count + 5 + sps.count + 5 + pps.count
    }
}
