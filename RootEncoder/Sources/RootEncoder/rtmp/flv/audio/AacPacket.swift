//
//  AacPacket.swift
//  app
//
//  Created by Pedro  on 16/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import Foundation

public class RtmpAacPacket: RtmpBasePacket {
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
    
    public override func createFlvPacket(buffer: Array<UInt8>, ts: UInt64, callback: (FlvPacket) -> Void) {
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
                
        var packetBuffer: [UInt8]
        if !configSend {
            let config = AudioSpecificConfig(type: objectType.rawValue, sampleRate: sampleRate, channels: isStereo ? 2 : 1)
            packetBuffer = [UInt8](repeating: 0, count: config.size + header.count)
            header[1] = AudioType.SEQUENCE.rawValue
            config.write(buffer: &packetBuffer, offset: header.count)
            configSend = true
        } else {
            packetBuffer = [UInt8](repeating: 0, count: length + header.count)
            header[1] = AudioType.RAW.rawValue
            packetBuffer[header.count..<packetBuffer.count] = buffer[0..<length]
        }
        packetBuffer[0..<header.count] = header[0..<header.count]
        let timeStamp = ts / 1000
        callback(FlvPacket(buffer: packetBuffer, timeStamp: Int64(timeStamp), length: packetBuffer.count, type: .AUDIO))
    }
    
    public override func reset(resetInfo: Bool = true) {
        configSend = false
    }
}
