//
//  File.swift
//  
//
//  Created by Pedro  on 26/8/24.
//

import Foundation

public class GenericStreamClient: StreamBaseClient {
    
    private let rtmpClient: RtmpStreamClient
    private let rtspClient: RtspStreamClient
    private var connectedStreamClient: StreamBaseClient? = nil
    
    public init(rtmpClient: RtmpStreamClient, rtspClient: RtspStreamClient) {
        self.rtmpClient = rtmpClient
        self.rtspClient = rtspClient
    }
    
    public func setAuth(user: String, password: String) {
        rtmpClient.setAuth(user: user, password: password)
        rtspClient.setAuth(user: user, password: password)
    }
    
    public func setOnlyAudio(onlyAudio: Bool) {
        rtmpClient.setOnlyAudio(onlyAudio: onlyAudio)
        rtspClient.setOnlyAudio(onlyAudio: onlyAudio)
    }
    
    public func setOnlyVideo(onlyVideo: Bool) {
        rtmpClient.setOnlyVideo(onlyVideo: onlyVideo)
        rtspClient.setOnlyVideo(onlyVideo: onlyVideo)
    }
    
    public func setRetries(reTries: Int) {
        rtmpClient.setRetries(reTries: reTries)
        rtspClient.setRetries(reTries: reTries)
    }
    
    public func reTry(delay: Int, reason: String, backUrl: String?) -> Bool {
        return connectedStreamClient?.reTry(delay: delay, reason: reason, backUrl: backUrl) ?? false
    }
    
    public func reTry(delay: Int, reason: String) -> Bool {
        return connectedStreamClient?.reTry(delay: delay, reason: reason, backUrl: nil) ?? false
    }
    
    public func setLogs(enabled: Bool) {
        rtmpClient.setLogs(enabled: enabled)
        rtspClient.setLogs(enabled: enabled)
    }
    
    public func hasCongestion() -> Bool {
        return hasCongestion(percentUsed: 20)
    }
    
    public func hasCongestion(percentUsed: Float) -> Bool {
        return connectedStreamClient?.hasCongestion(percentUsed: percentUsed) ?? false
    }
    
    public func resizeCache(newSize: Int) {
        rtmpClient.resizeCache(newSize: newSize)
        rtspClient.resizeCache(newSize: newSize)
    }
    
    public func getCacheSize() -> Int {
        return connectedStreamClient?.getCacheSize() ?? 0
    }
    
    public func clearCache() {
        rtmpClient.clearCache()
        rtspClient.clearCache()
    }
    
    public func getSentAudioFrames() -> Int {
        return connectedStreamClient?.getSentAudioFrames() ?? 0
    }
    
    public func getSentVideoFrames() -> Int {
        return connectedStreamClient?.getSentVideoFrames() ?? 0
    }
    
    public func getDroppedAudioFrames() -> Int {
        return connectedStreamClient?.getDroppedAudioFrames() ?? 0
    }
    
    public func getDroppedVideoFrames() -> Int {
        return connectedStreamClient?.getDroppedVideoFrames() ?? 0
    }
    
    public func resetSentAudioFrames() {
        rtmpClient.resetSentAudioFrames()
        rtspClient.resetSentAudioFrames()
    }
    
    public func resetSentVideoFrames() {
        rtmpClient.resetSentVideoFrames()
        rtspClient.resetSentVideoFrames()
    }
    
    public func resetDroppedAudioFrames() {
        rtmpClient.resetDroppedAudioFrames()
        rtspClient.resetDroppedAudioFrames()
    }
    
    public func resetDroppedVideoFrames() {
        rtmpClient.resetDroppedVideoFrames()
        rtspClient.resetDroppedVideoFrames()
    }
    
    func connecting(url: String) {
        connectedStreamClient = if url.lowercased().hasPrefix("rtmp") {
            rtmpClient
        } else if url.lowercased().hasPrefix("rtsp") {
            rtspClient
        } else {
            nil
        }
    }
}
