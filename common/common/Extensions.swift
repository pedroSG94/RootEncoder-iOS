//
//  Extensions.swift
//  common
//
//  Created by Pedro  on 20/3/24.
//

import Foundation

public extension Date {
    public var millisecondsSince1970:Int64 {
        Int64((timeIntervalSince1970 * 1000.0).rounded())
    }

    public init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}
