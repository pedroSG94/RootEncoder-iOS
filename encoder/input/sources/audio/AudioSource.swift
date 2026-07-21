//
//  File 2.swift
//  RootEncoder
//
//  Created by Pedro  on 5/10/24.
//

import common
import Foundation

public protocol AudioSource {
    func created() -> Bool
    func create(sampleRate: Int, isStereo: Bool) -> Bool
    func start(calback: GetMicrophoneData)
    func stop()
    func isRunning() -> Bool
    func release()
}
