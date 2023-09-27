//
//  Frame.swift
//  app
//
//  Created by Mac on 04/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import Foundation

public struct Frame {
    public var buffer: Array<UInt8>?
    var length: UInt32?
    public var timeStamp: UInt64?
    var flag: Int? = 1
}
