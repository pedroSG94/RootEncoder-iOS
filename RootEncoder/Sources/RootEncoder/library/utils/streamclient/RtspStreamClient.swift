//
//  File.swift
//  
//
//  Created by Pedro  on 16/7/24.
//

import Foundation

public class RtspStreamClient: StreamBaseClient {
    
    private let client: RtspClient
    private let listener: StreamClientListenter?
    
    public init(client: RtspClient, listener: StreamClientListenter?) {
        self.client = client
        self.listener = listener
    }
    
    public func setAuth(user: String, password: String) {
        client.setAuth(user: user, password: password)
    }
    
    public func setOnlyAudio(onlyAudio: Bool) {
        client.setOnlyAudio(onlyAudio: onlyAudio)
    }
    
    public func setOnlyVideo(onlyVideo: Bool) {
        client.setOnlyVideo(onlyVideo: onlyVideo)
    }
    
    public func setRetries(reTries: Int) {
        client.setRetries(reTries: reTries)
    }
    
    public func reTry(delay: Int, reason: String, backUrl: String?) -> Bool {
        let result = client.shouldRetry(reason: reason)
        if (result) {
            listener?.onRequestKeyframe()
            client.reconnect(delay: delay, backupUrl: backUrl)
        }
        return result
    }
    
    public func reTry(delay: Int, reason: String) -> Bool {
        return reTry(delay: delay, reason: reason, backUrl: nil)
    }
    
    public func setLogs(enabled: Bool) {
        client.setLogs(enabled: enabled)
    }
    
    public func hasCongestion() -> Bool {
        return hasCongestion(percentUsed: 20)
    }
    
    public func hasCongestion(percentUsed: Float) -> Bool {
        return client.hasCongestion(percentUsed: percentUsed)
    }
    
    public func resizeCache(newSize: Int) {
        client.resizeCache(newSize: newSize)
    }
    
    public func getCacheSize() -> Int {
        return client.getCacheSize()
    }
    
    public func clearCache() {
        client.clearCache()
    }
    
    public func getSentAudioFrames() -> Int {
        return client.getSentAudioFrames()
    }
    
    public func getSentVideoFrames() -> Int {
        return client.getSentVideoFrames()
    }
    
    public func getDroppedAudioFrames() -> Int {
        return client.getDroppedAudioFrames()
    }
    
    public func getDroppedVideoFrames() -> Int {
        return client.getDroppedVideoFrames()
    }
    
    public func resetSentAudioFrames() {
        client.resetSentAudioFrames()
    }
    
    public func resetSentVideoFrames() {
        client.resetSentVideoFrames()
    }
    
    public func resetDroppedAudioFrames() {
        client.resetDroppedAudioFrames()
    }
    
    public func resetDroppedVideoFrames() {
        client.resetDroppedVideoFrames()
    }
}
