//
//  File 2.swift
//  RootEncoder
//
//  Created by Pedro  on 5/10/24.
//

import Foundation

public protocol AudioSource {
    func create(sampleRate: Int, isStereo: Bool) -> Bool
    func start(calback: GetMicrophoneData)
    func stop()
    func isRunning() -> Bool
    func release()
}
