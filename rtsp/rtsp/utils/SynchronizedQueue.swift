//
//  ConcurrentFlvQueue.swift
//  app
//
//  Created by Pedro  on 16/9/23.
//  Copyright © 2023 pedroSG94. All rights reserved.
//

import Foundation

class SynchronizedQueue<T> {
    private var elements = [T]()
    private let semaphore = DispatchSemaphore(value: 0)
    private let queue: DispatchQueue
    private var size: Int
    
    init(label: String, size: Int) {
        queue = DispatchQueue(label: label)
        self.size = size
    }

    func enqueue(_ element: T) -> Bool {
        queue.sync {
            if (elements.count >= size) {
                return false
            } else {
                elements.append(element)
                semaphore.signal()
                return true
            }
        }
    }

    func dequeue() -> T? {
        var result: T?
        let _ = semaphore.wait(timeout: .now() + 0.01)
        queue.sync {
            if (!elements.isEmpty) {
                result = elements.removeFirst()
            }
        }
        return result
    }
    
    func clear() {
        queue.sync {
            elements.removeAll()
        }
    }
    
    func resizeSize(size: Int) {
        self.size = size
    }
    
    func itemsCount() -> Int {
        return elements.count
    }
    
    func remaining() -> Int {
        return size - elements.count
    }
}
