//
// Created by Pedro  on 24/4/22.
// Copyright (c) 2022 pedroSG94. All rights reserved.
//

import Foundation

public class AmfData: AmfActions {

    static func getAmfData(buffer: inout [UInt8]) throws -> AmfData {
        let identify: UInt8 = buffer.takeFirst(n: 1)[0]
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
            try amfData?.readBody(buffer: &buffer)
            return amfData!
        }
    }

    static func getMarkType(type: UInt8) -> AmfType {
        let amfType = AmfType.init(rawValue: type)
        return amfType ?? AmfType.STRING
    }

    public func readHeader(buffer: inout [UInt8]) throws -> AmfType {
        let byte = buffer.takeFirst(n: 1)[0]
        return AmfData.getMarkType(type: byte)
    }

    public func writeHeader() -> [UInt8] {
        Array(arrayLiteral: getType().rawValue)
    }

    public func writeHeader(socket: Socket) async throws {
        try socket.write(buffer: writeHeader())
    }

    public func readBody(buffer: inout [UInt8]) throws {

    }

    public func writeBody() -> [UInt8] {
        [UInt8]()
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
    func readBody(buffer: inout [UInt8]) throws
    func writeBody(socket: Socket) throws
    func getType() -> AmfType
    func getSize() -> Int
}
