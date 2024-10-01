//
//  BaseSender.swift
//  RootEncoder
//
//  Created by Pedro  on 1/10/24.
//

public class BaseSender {
    
    private var thread: Task<(), Never>? = nil
    private(set) var running = false
    private var cacheSize = 200
    let queue: SynchronizedQueue<MediaFrame>
    let callback: ConnectChecker

    var audioFramesSent = 0
    var videoFramesSent = 0
    var droppedAudioFrames = 0
    var droppedVideoFrames = 0
    let bitrateManager: BitrateManager
    var isEnableLogs = true
    
    public init(callback: ConnectChecker, tag: String) {
        self.callback = callback
        queue = SynchronizedQueue<MediaFrame>(label: "\(tag)SenderQueue", size: cacheSize)
        bitrateManager = BitrateManager(connectChecker: callback)
    }

    public func setVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?) { }
    public func setAudioInfo(sampleRate: Int, isStereo: Bool) { }
    public func onRun() { }
    public func stopImp(clear: Bool = true) { }
    
    public func sendMediaFrame(mediaFrame: MediaFrame) {
        if running && !queue.enqueue(mediaFrame) {
            if mediaFrame.type == MediaFrame.MediaType.VIDEO {
                print("Video frame discarded")
                droppedVideoFrames += 1
            } else {
                print("Audio frame discarded")
                droppedAudioFrames += 1
            }
        }
    }

    public func start() {
        queue.clear()
        running = true
        thread = Task(priority: .high) {
            onRun()
        }
    }

    public func stop(clear: Bool = true) {
        running = false
        thread?.cancel()
        thread = nil
        stopImp(clear: clear)
        queue.clear()
        videoFramesSent = 0
        audioFramesSent = 0
        droppedVideoFrames = 0
        droppedAudioFrames = 0
    }
    
    public func hasCongestion(percentUsed: Float) -> Bool {
        let size = queue.itemsCount()
        let remaining = queue.remaining()
        let capacity = size + remaining
        return Double(size) >= Double(capacity) * Double(percentUsed) / 100 //more than 20% queue used. You could have congestion
    }
    
    public func resizeCache(newSize: Int) {
        queue.resizeSize(size: newSize)
    }
    
    public func getCacheSize() -> Int {
        return cacheSize
    }
    
    public func clearCache() {
        queue.clear()
    }
}
