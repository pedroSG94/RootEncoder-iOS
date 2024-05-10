//
//  G711Packet.swift
//  rtmp
//
//  Created by Pedro  on 29/3/24.
//

import Foundation

public class RtmpG711Packet: RtmpBasePacket {
    private var header = [UInt8](repeating: 0, count: 1)
    private var audioSize = AudioSize.SND_16_BIT
    
    func sendAudioInfo(audioSize: AudioSize = AudioSize.SND_16_BIT) {
        self.audioSize = audioSize
    }
    
    public override func createFlvPacket(buffer: Array<UInt8>, ts: UInt64, callback: (FlvPacket) -> Void) {
        let length = buffer.count
        header[0] = AudioSoundType.MONO.rawValue | (audioSize.rawValue << 1) | (AudioSoundRate.SR_5_5K.rawValue << 2) | (AudioFormat.G711_A.rawValue << 4)
                
        var packetBuffer = [UInt8](repeating: 0, count: length + header.count)
        packetBuffer[header.count..<packetBuffer.count] = buffer[0..<length]
        packetBuffer[0..<header.count] = header[0..<header.count]
        let timeStamp = ts / 1000
        callback(FlvPacket(buffer: packetBuffer, timeStamp: Int64(timeStamp), length: packetBuffer.count, type: .AUDIO))
    }
    
    public override func reset(resetInfo: Bool = true) {
    }
}
