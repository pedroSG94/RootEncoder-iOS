//
//  VideoSpecificConfigAVC.swift
//  app
//
//  Created by Pedro  on 19/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import Foundation

public class VideoSpecificConfigAVC {
    
    let sps: Array<UInt8>
    let pps: Array<UInt8>
    let profileIop: ProfileIop
    var size = 0
    
    init(sps: Array<UInt8>, pps: Array<UInt8>, profileIop: ProfileIop) {
        self.sps = sps
        self.pps = pps
        self.profileIop = profileIop
        size = calculateSize(sps: sps, pps: pps)
    }
    
    func write(buffer: inout [UInt8], offset: Int) {
        // 5 bytes sps/pps header
        buffer[offset] = 0x01
        let profileIdc = sps[1]
        buffer[offset + 1] = profileIdc
        buffer[offset + 2] = profileIop.rawValue
        let levelIdc = sps[3]
        buffer[offset + 3] = levelIdc
        buffer[offset + 4] = 0xff
        // 3 bytes size of sps
        buffer[offset + 5] = 0xe1
        buffer[offset + 6] = UInt8((sps.count >> 8) & 0xff)
        buffer[offset + 7] = UInt8(sps.count & 0xff)
        // N bytes of sps
        buffer[offset + 8..<offset + 8 + sps.count] = sps[0..<sps.count]
        // 3 bytes size of pps
        buffer[sps.count + offset + 8] = 0x01
        buffer[sps.count + offset + 9] = UInt8((pps.count >> 8) & 0xff)
        buffer[sps.count + offset + 10] = UInt8(pps.count & 0xff)
        // N bytes of pps
        buffer[sps.count + offset + 11..<sps.count + offset + 11 + pps.count] = pps[0..<pps.count]
    }
    
    
    func calculateSize(sps: Array<UInt8>, pps: Array<UInt8>) -> Int {
        return 5 + 3 + sps.count + 5 + 3 + pps.count
    }
}
