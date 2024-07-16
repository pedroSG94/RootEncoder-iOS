//
//  File.swift
//  
//
//  Created by Pedro  on 16/7/24.
//

import Foundation

public protocol StreamBaseClient {
    func setAuth(user: String, password: String)
    func setOnlyAudio(onlyAudio: Bool)
    func setOnlyVideo(onlyVideo: Bool)
    func setRetries(reTries: Int)
    func reTry(delay: Int, reason: String, backUrl: String?) -> Bool
    func reTry(delay: Int, reason: String) -> Bool
    func setLogs(enabled: Bool)
    func hasCongestion() -> Bool
    func hasCongestion(percentUsed: Float) -> Bool
    func resizeCache(newSize: Int)
    func getCacheSize() -> Int
    func clearCache()
    func getSentAudioFrames() -> Int
    func getSentVideoFrames() -> Int
    func getDroppedAudioFrames() -> Int
    func getDroppedVideoFrames() -> Int
    func resetSentAudioFrames()
    func resetSentVideoFrames()
    func resetDroppedAudioFrames()
    func resetDroppedVideoFrames()
}
