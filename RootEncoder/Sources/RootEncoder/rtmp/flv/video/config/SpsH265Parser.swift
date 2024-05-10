//
//  SpsH265Parser.swift
//  rtmp
//
//  Created by Pedro  on 24/3/24.
// ISO/IEC 23008-2 7.3.2.2.1
//

import Foundation

class SpsH265Parser {
    var generalProfileSpace = 0
    var generalTierFlag = 0
    var generalProfileIdc = 0
    var generalProfileCompatibilityFlags = 0
    var generalConstraintIndicatorFlags = 0
    var generalLevelIdc = 0
    var chromaFormat = 0
    var bitDepthLumaMinus8 = 0
    var bitDepthChromaMinus8 = 0
    
    func parse(sps: Array<UInt8>) {
        let rbsp = RtmpBitBuffer.extractRbsp(buffer: sps)
        let bitBuffer = RtmpBitBuffer(buffer: rbsp)
        //Dropping nal_unit_header
        let _ = bitBuffer.getLong(i: 16)
        //sps_video_parameter_set_id
        let _ = bitBuffer.get(i: 4)
        //sps_max_sub_layers_minus1
        let maxSubLayersMinus1 = bitBuffer.get(i: 3)
        //sps_temporal_id_nesting_flag
        let _ = bitBuffer.get(i: 1)
        //start profile_tier_level
        generalProfileSpace = Int(bitBuffer.get(i: 2))
        generalTierFlag = if bitBuffer.getBool() {
            1
        } else {
            0
        }
        generalProfileIdc = Int(bitBuffer.getShort(i: 5))
        
        generalProfileCompatibilityFlags = Int(bitBuffer.getInt(i: 32))
        generalConstraintIndicatorFlags = Int(bitBuffer.getLong(i: 48))
        generalLevelIdc = Int(bitBuffer.get(i: 8))
        
        var subLayerProfilePresentFlag = Array<Bool>()
        var subLayerLevelPresentFlag = Array<Bool>()
        for _ in 0..<maxSubLayersMinus1 {
            subLayerProfilePresentFlag.append(bitBuffer.getBool())
            subLayerLevelPresentFlag.append(bitBuffer.getBool())
        }
        
        if maxSubLayersMinus1 > 0 {
            for _ in maxSubLayersMinus1...8 {
                let _ = bitBuffer.getLong(i: 2)
            }
        }
        
        for i in 0..<maxSubLayersMinus1 {
            if subLayerProfilePresentFlag[Int(i)] {
                let _ = bitBuffer.getLong(i: 32)
                let _ = bitBuffer.getLong(i: 32)
                let _ = bitBuffer.getLong(i: 24)
            }
            if subLayerLevelPresentFlag[Int(i)] {
                let _ = bitBuffer.getLong(i: 8)
            }
        }
        //end profile_tier_level

        //sps_seq_parameter_set_id
        let _ = bitBuffer.readUE()
        //chroma_format_idc
        chromaFormat = bitBuffer.readUE()
        if (chromaFormat == 3) {
          //separate_colour_plane_flag
            let _ = bitBuffer.getBool()
        }
        //pic_width_in_luma_samples
        let _ = bitBuffer.readUE()
        //pic_height_in_luma_samples
        let _ = bitBuffer.readUE()
        //conformance_window_flag
        let conformanceWindowFlag = bitBuffer.getBool()
        if conformanceWindowFlag {
            //conf_win_left_offset
            let _ = bitBuffer.readUE()
            //conf_win_right_offset
            let _ = bitBuffer.readUE()
            //conf_win_top_offset
            let _ = bitBuffer.readUE()
            //conf_win_bottom_offset
            let _ = bitBuffer.readUE()
        }
        //bit_depth_luma_minus8
        bitDepthLumaMinus8 = bitBuffer.readUE()
        //bit_depth_chroma_minus8
        bitDepthChromaMinus8 = bitBuffer.readUE()

        //The buffer continue but we don't need read more
    }
}
