import Common
import Encoder
import RTMP
import RTSP
import SRT
//
//  Filter.swift
//  RootEncoder
//
//  Created by Pedro  on 09/07/2026.
//

public struct Filter {
    var filterAction: FilterAction
    var position: Int
    var baseFilterRender: BaseFilterRender
}
