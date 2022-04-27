//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class AmfData: AmfActions {

    static func getAmfData(socket: Socket) throws -> AmfData {
        let identify: UInt8 = try socket.readUntil(length: 1)[0]
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
            try amfData?.readBody(socket: socket)
            return amfData!
        }
    }

    static func getMarkType(type: UInt8) -> AmfType {
        let amfType = AmfType.init(rawValue: type)
        return amfType ?? AmfType.STRING
    }

    func writeHeader(socket: Socket) throws {
        try socket.write(buffer: Array(arrayLiteral: getType().rawValue))
    }

    public func readBody(socket: Socket) throws {

    }

    public func writeBody(socket: Socket) throws {

    }

    public func getType() -> AmfType {
        AmfType.UNDEFINED
    }

    public func getSize() -> Int {
        0
    }
}

public protocol AmfActions {
    func readBody(socket: Socket) throws
    func writeBody(socket: Socket) throws
    func getType() -> AmfType
    func getSize() -> Int
}