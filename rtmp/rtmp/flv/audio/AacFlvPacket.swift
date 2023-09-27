//
//  AacPacket.swift
//  app
//
//  Created by Pedro  on 16/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import Foundation

public class AacFlvPacket {
    private var header = [UInt8](repeating: 0, count: 2)
    private var configSend = false
    
    private var sampleRate = 44100
    private var isStereo = true
    private var audioSize = AudioSize.SND_16_BIT
    private let objectType = AudioObjectType.AAC_LC
    
    enum AudioType: UInt8 {
        case SEQUENCE = 0x00
        case RAW = 0x01
    }
    
    func sendAudioInfo(sampleRate: Int, isStereo: Bool, audioSize: AudioSize = AudioSize.SND_16_BIT) {
        self.sampleRate = sampleRate
        self.isStereo = isStereo
        self.audioSize = audioSize
    }
    
    func createFlvAudioPacket(buffer: Array<UInt8>, ts: UInt64, callback: (FlvPacket) -> Void) {
        let length = buffer.count
        header[0] = isStereo ? AudioSoundType.STEREO.rawValue : AudioSoundType.MONO.rawValue
        header[0] |= (audioSize.rawValue << 1)
                
        let soundRate: AudioSoundRate
        switch sampleRate {
            case 44100: soundRate = .SR_44_1K
            case 22050: soundRate = .SR_22K
            case 11025: soundRate = .SR_11K
            case 5500: soundRate = .SR_5_5K
            default: soundRate = .SR_44_1K
        }
        header[0] |= (soundRate.rawValue << 2)
        header[0] |= (AudioFormat.AAC.rawValue << 4)
                
        var buffer: [UInt8]
        if !configSend {
            let config = AudioSpecificConfig(type: objectType.rawValue, sampleRate: sampleRate, channels: isStereo ? 2 : 1)
            buffer = [UInt8](repeating: 0, count: config.size + header.count)
            header[1] = AudioType.SEQUENCE.rawValue
            config.write(buffer: &buffer, offset: header.count)
            configSend = true
        } else {
            let dataSize = Int(length)
            buffer = [UInt8](repeating: 0, count: dataSize + header.count)
            header[1] = AudioType.RAW.rawValue
            buffer[header.count..<dataSize] = buffer[0..<dataSize]
        }
        buffer[0..<header.count] = header[0..<header.count]
        let ts = ts / 1000
        callback(FlvPacket(buffer: buffer, timeStamp: Int64(ts), length: buffer.count, type: .AUDIO))
    }
    
    func reset() {
        configSend = false
    }
}
