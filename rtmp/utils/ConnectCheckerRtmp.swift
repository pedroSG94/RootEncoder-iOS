//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

public protocol ConnectCheckerRtmp {

    func onConnectionSuccessRtmp()

    func onConnectionFailedRtmp(reason: String)

    func onNewBitrateRtmp(bitrate: UInt64)

    func onDisconnectRtmp()

    func onAuthErrorRtmp()

    func onAuthSuccessRtmp()
}