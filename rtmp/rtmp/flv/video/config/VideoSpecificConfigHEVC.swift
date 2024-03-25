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
        
        let configurationVersion = 1
        buffer[offset] = UInt8(configurationVersion)
        
    }
    
    private func writeNaluArray(type: UInt8, naluByteBuffer: Array<UInt8>, buffer: inout Array<UInt8>) {
        let arrayCompleteness = 1
        let reserved = 0
        let numNalus = 1
    }
    
    private func calculateSize(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>) -> Int {
        return 23 + 5 + vps.count + 5 + sps.count + 5 + pps.count
    }
}
