//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class AmfData: AmfActions {

    func getAmfData(socket: Socket) throws -> AmfData {
        let identify: UInt8 = socket.readUntil(length: 1)[0]
        let type = getMarkType(type: identify)
        let amfData: AmfData? = {
            switch type {
            case AmfType.NUMBER:
                return AmfNumber()
            case AmfType.BOOLEAN:
                return AmfBoolean()
            case AmfType.STRING:
                return AmfString()
            case AmfType.OBJECT:
                return AmfObject()
            case AmfType.NULL:
                return AmfNull()
            case AmfType.UNDEFINED:
                return AmfUndefined()
            case AmfType.ECMA_ARRAY:
                return AmfEcmaArray()
            case AmfType.STRICT_ARRAY:
                return AmfStrictArray()
            default:
                return nil
            }
        }()
        if (amfData == nil) {
            throw IOException.runtimeError("Unimplemented AMF data type: \(type)")
        } else {
            amfData?.readBody(socket: socket)
            return amfData!
        }
    }

    func getMarkType(type: UInt8) -> AmfType {
        let amfType = AmfType.init(rawValue: type)
        return amfType ?? AmfType.STRING
    }

    public func readBody(socket: Socket) {
        <#code#>
    }

    public func writeBody(socket: Socket) {
        <#code#>
    }

    public func getType() -> AmfType {
        <#code#>
    }

    public func getSize() -> Int {
        <#code#>
    }
}

public protocol AmfActions {
    func readBody(socket: Socket)
    func writeBody(socket: Socket)
    func getType() -> AmfType
    func getSize() -> Int
}