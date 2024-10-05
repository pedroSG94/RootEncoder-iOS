//
//  File.swift
//  RootEncoder
//
//  Created by Pedro  on 5/10/24.
//

import Foundation

public protocol VideoSource {
    func created() -> Bool
    func create(width: Int, height: Int, fps: Int, rotation: Int) -> Bool
    func start(metalInterface: MetalInterface)
    func stop()
    func isRunning() -> Bool
    func release()
}
