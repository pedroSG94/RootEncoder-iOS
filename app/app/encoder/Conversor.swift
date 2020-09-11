//
//  Conversor.swift
//  app
//
//  Created by Mac on 06/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import Foundation

public func intToBytes<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
    withUnsafeBytes(of: value.littleEndian, Array.init)
}

public func byteArray<T>(from value: [T]) -> [UInt8] where T: FixedWidthInteger {
    var buffer = Array<UInt8>()
    value.forEach {
        buffer.append(contentsOf: intToBytes(from: $0))
    }
    return buffer
}
