import Foundation
import Network

public class Socket: NSObject, StreamDelegate {

    var host: String
    private var connection: NWConnection? = nil
    private var bufferAppend: [UInt8]? = nil
    private let lock = DispatchQueue(label: "com.pedro.Socket.sync")
    private let readLock = DispatchQueue(label: "com.pedro.Socket.sync.read")

    /**
        TCP or TCP/TLS socket
     */
    public init(tlsEnabled: Bool, host: String, port: Int) {
        self.host = host
        let parameters: NWParameters = tlsEnabled ? .tls : .tcp
        connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port("\(port)")!, using: parameters)
    }

    /**
        UDP socket
    */
    public init(host: String, localPort: Int, port: Int) {
        self.host = host
        let localEndpoint = NWEndpoint.hostPort(host: "0.0.0.0", port: NWEndpoint.Port("\(localPort)")!)
        let parameters = NWParameters.udp
        parameters.requiredLocalEndpoint = localEndpoint
        connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port("\(port)")!, using: parameters)
    }
    
    public func connect() async throws {
        let _ = try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<String?, Error>) in
            connection?.stateUpdateHandler = { (newState) in
                switch (newState) {
                case .ready:
                    continuation.resume(returning: nil)
                    self.connection?.stateUpdateHandler = nil
                    return
                case .setup:
                    break
                case .waiting(_):
                    continuation.resume(throwing: IOException.runtimeError("connection not found"))
                    self.connection?.stateUpdateHandler = nil
                    return
                case .preparing:
                     break
                case .cancelled:
                    continuation.resume(throwing: IOException.runtimeError("connection cancelled"))
                    self.connection?.stateUpdateHandler = nil
                    return
                case .failed(_):
                    continuation.resume(throwing: IOException.runtimeError("connection failed"))
                    self.connection?.stateUpdateHandler = nil
                    return
                @unknown default:
                    break
                }
            }
            connection?.start(queue: .global())
        }
    }
    
    public func disconnect() {
        connection?.forceCancel()
        connection = nil
    }

    public func write(buffer: [UInt8]) async throws {
        let data = Data(buffer)
        try await write(data: data)
    }

    
    public func write(data: Data) async throws {
        let _ = try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Bool, Error>) in
            if (connection == nil) {
                continuation.resume(throwing: IOException.runtimeError("socket closed"))
            } else {
                connection?.send(content: data, completion: NWConnection.SendCompletion.contentProcessed(( { error in
                    if (error != nil) {
                        continuation.resume(throwing: IOException.runtimeError("\(String(describing: error))"))
                    } else {
                        continuation.resume(returning: true)
                    }
                })))
            }
        }
    }

    public func write(buffer: [UInt8], size: Int) async throws {
        let data = Data(bytes: buffer, count: size)
        try await write(data: data)
    }
    
    public func write(data: String) async throws {
        let buffer = [UInt8](data.utf8)
        try await self.write(buffer: buffer)
    }

    public func read() async throws -> [UInt8] {
        let data: Data = try await read()
        var bytes = [UInt8](data)
        if (bufferAppend != nil) {
            bytes.insert(contentsOf: bufferAppend!, at: 0)
        }
        return bytes
    }

    public func readString() async throws -> String {
        let data: Data = try await read()
        let message = String(data: data, encoding: String.Encoding.utf8)!
        return message
    }

    public func read() async throws -> Data {
        try await readUntil(length: 65536)
    }

    public func readUntil(length: Int) async throws -> [UInt8] {
        let data: Data = try await readUntil(length: length)
        var bytes = [UInt8](data)
        if (bufferAppend != nil) {
            bytes.insert(contentsOf: bufferAppend!, at: 0)
        }
        return bytes
    }
    
    private func readUntil(length: Int) async throws -> Data {
        let result = try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Data, Error>) in
            if (connection == nil) {
                continuation.resume(throwing: IOException.runtimeError("socket closed"))
            } else {
                connection?.receiveDiscontiguous(minimumIncompleteLength: 1, maximumLength: length, completion: { data, context, isComplete, error in
                    if let data = data {
                        continuation.resume(returning: Data(data))
                    } else if let error = error {
                        let e = "fail to read \(error)"
                        continuation.resume(throwing: IOException.runtimeError(e))
                    } else if isComplete {
                        let e = "fail to read EOF"
                        continuation.resume(throwing: IOException.runtimeError(e))
                    }
                })
            }
        }
        return result
    }
}

extension Data {

    init(copying dd: DispatchData) {
        var result = Data(count: dd.count)
        result.withUnsafeMutableBytes { buf in
            _ = dd.copyBytes(to: buf)
        }
        self = result
    }
}
