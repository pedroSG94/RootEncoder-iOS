//
// Created by Pedro  on 1/12/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//
// The C0 and S0 packets are a single octet
//
// The version defined by this
// specification is 3. Values 0-2 are deprecated values used by
// earlier proprietary products; 4-31 are reserved for future
// implementations; and 32-255 are not allowed
// 0 1 2 3 4 5 6 7
// +-+-+-+-+-+-+-+-+
// | version |
// +-+-+-+-+-+-+-+-+
//
// The C1 and S1 packets are 1536 octets long
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// | time (4 bytes) | local generated timestamp
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// | zero (4 bytes) |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// | random bytes |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// | random bytes |
// | (cont) |
// | .... |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//
// The C2 and S2 packets are 1536 octets long, and nearly an echo of S1 and C1 (respectively).
//
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// | time (4 bytes) | s1 timestamp for c2 or c1 for s2. In this case s1
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// | time2 (4 bytes) | timestamp of previous packet (s1 or c1). In this case c1
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// | random echo | random data field sent by the peer in s1 for c2 or s2 for c1.
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// | random echo | random data field sent by the peer in s1 for c2 or s2 for c1.
// | (cont) |
// | .... |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//


import Foundation

public class Handshake {

    private let protocolVersion: UInt8 = 0x03
    private let handshakeSize = 1536
    private var timestampC1 = 0

    func sendHandshake(socket: Socket) throws -> Bool {
        writeC0(socket: socket)
        let c1 = writeC1(socket: socket)
        let _ = try readS0(socket: socket)
        let s1 = readS1(socket: socket)
        writeC2(socket: socket, s1: s1)
        let _ = readS2(socket: socket, c1: c1)
        return true
    }

    private func writeC0(socket: Socket) {
        print("writing C0")
        let c0 = [UInt8](arrayLiteral: protocolVersion)
        socket.write(buffer: c0)
        print("write C0 successful")
    }

    private func writeC1(socket: Socket) -> [UInt8] {
        print("writing C1")
        var c1 = [UInt8](repeating: 0x00, count: handshakeSize)

        let timestamp: UInt32 = UInt32(Date().millisecondsSince1970 / 1000)
        print("writing time \(timestamp) to c1")
        let timestampData = withUnsafeBytes(of: timestamp.bigEndian) {
            Array($0)
        }
        c1[0...timestampData.count - 1] = timestampData[0...timestampData.count - 1]

        print("writing zero to c1")
        let zeroData = [UInt8](arrayLiteral: 0x00, 0x00, 0x00, 0x00)
        c1[timestampData.count...timestampData.count + zeroData.count - 1] = zeroData[0...zeroData.count - 1]

        print("writing random to c1")
        var randomData = [UInt8](repeating: 0x00, count: handshakeSize - 8)
        for (index, _) in randomData.enumerated() {
            randomData[index] = UInt8(UInt8.random(in: 0...UInt8.max))
        }
        c1[timestampData.count + zeroData.count...c1.count - 1] = randomData[0...randomData.count - 1]
        socket.write(buffer: c1)
        print("write C1 successful")
        return c1
    }

    private func writeC2(socket: Socket, s1: [UInt8]) {
        print("writing C2")
        socket.write(buffer: s1)
        print("write C2 successful")
    }

    private func readS0(socket: Socket) throws -> [UInt8] {
        print("reading S0")
        let s0: [UInt8] = socket.readUntil(length: 1)
        let response = s0[0]
        if (response == protocolVersion || response == 72) {
            return [UInt8](arrayLiteral: response)
        } else {
            throw HandshakeError.runtimeError("unexpected \(response) S0 received")
        }
    }

    private func readS1(socket: Socket) -> [UInt8] {
        print("reading S1")
        let s1: [UInt8] = socket.readUntil(length: handshakeSize)
        print("read S1 successful")
        return s1
    }

    private func readS2(socket: Socket, c1: [UInt8]) -> [UInt8] {
        print("reading S2")
        let s2: [UInt8] = socket.readUntil(length: handshakeSize)
        if (!s2.elementsEqual(c1)) {
            print("S2 content is different that C1")
        }
        print("read S2 successful")
        return s2
    }

    enum HandshakeError: Error {
        case runtimeError(String)
    }
}
