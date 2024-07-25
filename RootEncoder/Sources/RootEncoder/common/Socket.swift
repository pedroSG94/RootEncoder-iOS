import Foundation
import Network

public class Socket: NSObject, StreamDelegate {

    public var host: String
    private var connection: NWConnection? = nil
    private let thread = DispatchQueue(label: "SocketThread")
    private let semaphore = DispatchSemaphore(value: 0)
    private var inputBuffer = Data()
    private var outputBuffer = Data()
    
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
    
    public func connect() throws {
        connection?.stateUpdateHandler = { (newState) in
            switch (newState) {
            case .ready:
                self.connection?.stateUpdateHandler = nil
                self.onDataReceived(connection: self.connection!)
                return
            case .setup:
                break
            case .waiting(_):
                self.connection?.stateUpdateHandler = nil
                return
            case .preparing:
                 break
            case .cancelled:
                self.connection?.stateUpdateHandler = nil
                return
            case .failed(_):
                self.connection?.stateUpdateHandler = nil
                return
            @unknown default:
                break
            }
        }
        connection?.start(queue: thread)
    }
    
    public func disconnect() {
        connection?.forceCancel()
        connection = nil
    }

    public func write(buffer: [UInt8]) throws {
        let data = Data(buffer)
        try write(data: data)
    }

    public func write(data: Data) throws {
        outputBuffer.append(data)
    }
    
    public func flush() {
        let data = outputBuffer
        if !data.isEmpty {
            outputBuffer.removeFirst(data.count)
            connection?.send(content: data, completion: .contentProcessed { error in
            })
        }
    }

    public func write(buffer: [UInt8], size: Int) throws {
        let data = Data(bytes: buffer, count: size)
        try write(data: data)
    }
    
    public func write(data: String) throws {
        let buffer = [UInt8](data.utf8)
        try self.write(buffer: buffer)
    }

    public func read() throws -> [UInt8] {
        let data: Data = try read()
        let bytes = [UInt8](data)
        return bytes
    }

    public func readString() throws -> String {
        let data: Data = try read()
        let message = String(data: data, encoding: String.Encoding.utf8)
        return message ?? ""
    }

    public func read() throws -> Data {
        if !inputBuffer.isEmpty {
            let data = inputBuffer
            inputBuffer.removeFirst(data.count)
            return data
        } else {
            let result = semaphore.wait(timeout: .now() + 5)
            if result == DispatchTimeoutResult.success {
                return try read()
            } else {
                throw IOException.runtimeError("read timeout")
            }
        }
    }

    public func readUntil(length: Int) throws -> [UInt8] {
        let data: Data = try readUntil(length: length)
        let bytes = [UInt8](data)
        return bytes
    }
    
    private func readUntil(length: Int) throws -> Data {
        if inputBuffer.count >= length {
            let data = inputBuffer.prefix(length)
            inputBuffer.removeFirst(data.count)
            return data
        } else {
            let result = semaphore.wait(timeout: .now() + 5)
            if result == DispatchTimeoutResult.success {
                return try readUntil(length: length)
            } else {
                throw IOException.runtimeError("read timeout")
            }
        }
    }
    
    private func onDataReceived(connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 0, maximumLength: 256) { [weak self] data, _, _, _ in
            guard let self = self, let data = data else {
                return
            }
            inputBuffer.append(data)
            semaphore.signal()
            onDataReceived(connection: connection)
        }
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
