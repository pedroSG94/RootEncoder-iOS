//
//  ConcurrentFlvQueue.swift
//  app
//
//  Created by Pedro  on 16/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import Foundation

public class SynchronizedQueue<T> {
    private var elements = [T]()
    private let semaphore = DispatchSemaphore(value: 0)
    private let queue: DispatchQueue
    private var size: Int
    
    public init(label: String, size: Int) {
        queue = DispatchQueue(label: label)
        self.size = size
    }

    public func enqueue(_ element: T) -> Bool {
        queue.sync {
            if (elements.count >= size) {
                semaphore.signal()
                return false
            } else {
                elements.append(element)
                semaphore.signal()
                return true
            }
        }
    }

    public func dequeue() -> T? {
        var result: T?
        queue.sync {
            if (!elements.isEmpty) {
                result = elements.removeFirst()
            } else {
                let _ = semaphore.wait(timeout: .now() + 0.01)
            }
        }
        return result
    }
    
    public func clear() {
        queue.sync {
            elements.removeAll()
        }
    }
    
    public func resizeSize(size: Int) {
        self.size = size
    }
    
    public func itemsCount() -> Int {
        return elements.count
    }
    
    public func remaining() -> Int {
        return size - elements.count
    }
}
