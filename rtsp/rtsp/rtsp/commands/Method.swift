//
//  Method.swift
//  rtsp
//
//  Created by Pedro  on 3/10/23.
//

import Foundation

public enum Method: String {
    case OPTIONS = "OPTIONS"
    case ANNOUNCE = "ANNOUNCE"
    case RECORD = "RECORD"
    case SETUP = "SETUP"
    case DESCRIBE = "DESCRIBE"
    case TEARDOWN = "TEARDOWN"
    case PLAY = "PLAY"
    case PAUSE = "PAUSE"
    case SET_PARAMETERS = "SET_PARAMETERS"
    case GET_PARAMETERS = "GET_PARAMETERS"
    case REDIRECT = "REDIRECT"
    case UNKNOWN = "UNKNOWN"
}
