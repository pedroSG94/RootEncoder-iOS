//
//  File.swift
//  
//
//  Created by Pedro  on 10/5/24.
//

import Foundation
import AVFoundation

public class G711Codec {
    
    public init() {}
    
    public func configure(sampleRate: Double, channels: UInt32) throws {
        if sampleRate != 8000 || channels != 1 {
            throw IOException.runtimeError("G711 codec only support 8000 sampleRate and mono channel")
        }
    }
    
    public func encode(buffer: Array<UInt8>, offset: Int, size: Int) -> Array<UInt8>{
        var j = offset
        let count = size / 2
        var out = [UInt8](repeating: 0, count: count)
        for i in 0..<count {
            let sample = UInt16(buffer[j]) & 0xff | (UInt16(buffer[j + 1]) << 8)
            out[i] = linearToALawSample(sample)
            j += 2
        }
        return out
    }
    
    public func decode(src: Array<UInt8>, offset: Int, len: Int) -> Array<UInt8>{
        var j = 0
        var out = [UInt8](repeating: 0, count: src.count * 2)
        for i in 0..<len {
            let s = aLawDecompressTable[Int(src[i + offset]) & 0xff]
            out[j] = UInt8(s & 0xff)
            out[j + 1] = UInt8((s >> 8) & 0xff)
            j += 2
        }
        return out
    }
    
    private func linearToALawSample(_ mySample: UInt16) -> UInt8 {
        var sample = Int16(bitPattern: mySample)
        let sign = ~sample >> 8 & 0x80
        if sign != 0x80 {
            sample = ~sample
        }
        if sample > cClip {
            sample = cClip
        }
        var s: Int
        if sample >= 256 {
            let exponent = Int(aLawCompressTable[Int(sample) >> 8 & 0x7F])
            let mantissa = Int(sample) >> exponent + 3 & 0x0F
            s = exponent << 4 | mantissa
        } else {
            s = Int(sample) >> 4
        }
        s = s ^ (Int(sign) ^ 0x55)
        return s.toUInt8Array()[0]
    }
    
    private let cClip: Int16 = 32635
    private let aLawDecompressTable: [Int16] = [
        -5504, -5248, -6016, -5760, -4480, -4224, -4992, -4736, -7552, -7296, -8064, -7808, -6528, -6272, -7040, -6784, -2752, -2624, -3008, -2880, -2240, -2112, -2496, -2368, -3776, -3648, -4032, -3904, -3264, -3136, -3520, -3392, -22016, -20992, -24064, -23040, -17920, -16896, -19968, -18944, -30208, -29184, -32256, -31232, -26112, -25088, -28160, -27136, -11008, -10496, -12032, -11520, -8960, -8448, -9984, -9472, -15104, -14592, -16128, -15616, -13056, -12544, -14080, -13568, -344, -328, -376,
        -360, -280, -264, -312, -296, -472, -456, -504, -488, -408, -392, -440, -424, -88, -72, -120, -104, -24, -8, -56, -40, -216, -200, -248, -232, -152, -136, -184, -168, -1376, -1312, -1504, -1440, -1120, -1056, -1248, -1184, -1888, -1824, -2016, -1952, -1632, -1568, -1760, -1696, -688, -656, -752, -720, -560, -528, -624, -592, -944, -912, -1008, -976, -816, -784, -880, -848, 5504, 5248, 6016, 5760, 4480, 4224, 4992, 4736, 7552, 7296, 8064, 7808, 6528, 6272, 7040, 6784, 2752, 2624,
        3008, 2880, 2240, 2112, 2496, 2368, 3776, 3648, 4032, 3904, 3264, 3136, 3520, 3392, 22016, 20992, 24064, 23040, 17920, 16896, 19968, 18944, 30208, 29184, 32256, 31232, 26112, 25088, 28160, 27136, 11008, 10496, 12032, 11520, 8960, 8448, 9984, 9472, 15104, 14592, 16128, 15616, 13056, 12544, 14080, 13568, 344, 328, 376, 360, 280, 264, 312, 296, 472, 456, 504, 488, 408, 392, 440, 424, 88, 72, 120, 104, 24, 8, 56, 40, 216, 200, 248, 232, 152, 136, 184, 168, 1376, 1312, 1504, 1440, 1120,
        1056, 1248, 1184, 1888, 1824, 2016, 1952, 1632, 1568, 1760, 1696, 688, 656, 752, 720, 560, 528, 624, 592, 944, 912, 1008, 976, 816, 784, 880, 848
    ]
    private let aLawCompressTable: [UInt8] = [
        1, 1, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
    ]
}
