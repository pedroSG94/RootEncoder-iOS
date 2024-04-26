//
//  ConnectChecker.swift
//  common
//
//  Created by Pedro  on 20/3/24.
//

import Foundation

public protocol ConnectChecker {
    
    func onConnectionSuccess()
    
    func onConnectionFailed(reason: String)
    
    func onNewBitrate(bitrate: UInt64)
    
    func onDisconnect()
    
    func onAuthError()
    
    func onAuthSuccess()
}
