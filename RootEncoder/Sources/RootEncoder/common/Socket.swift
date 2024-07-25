import Foundation
import Network

public class Socket: NSObject, StreamDelegate {

    public var host: String
    private var connection: NWConnection? = nil
    private let thread = DispatchQueue(label: "SocketThread")
    private let semaphore = DispatchSemaphore(value: 0)
    private var inputBuffer = Data()
    private var outputBuffer = Data()
    private var callback: SocketCallback?
    private var connected = false
    private var timeoutHandler: DispatchWorkItem?
    
    /**
        TCP or TCP/TLS socket
     */
    public init(tlsEnabled: Bool, host: String, port: Int, callback: SocketCallback?) {
        self.host = host
        self.callback = callback
        let parameters: NWParameters = tlsEnabled ? .tls : .tcp
        connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port("\(port)")!, using: parameters)
    }

    /**
        UDP socket
    */
    public init(host: String, localPort: Int, port: Int, callback: SocketCallback?) {
        self.host = host
        self.callback = callback
        let localEndpoint = NWEndpoint.hostPort(host: "0.0.0.0", port: NWEndpoint.Port("\(localPort)")!)
        let parameters = NWParameters.udp
        parameters.requiredLocalEndpoint = localEndpoint
        connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port("\(port)")!, using: parameters)
    }
    
    public func setCallback(callback: SocketCallback) {
        self.callback = callback
    }
    
    public func connect() throws {
        let newTimeoutHandler = DispatchWorkItem { [weak self] in
            guard let self = self, self.timeoutHandler?.isCancelled == false else {
                return
            }
            disconnect(error: "connection timeout")
        }
        timeoutHandler = newTimeoutHandler
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + .seconds(5), execute: newTimeoutHandler)
        connection?.stateUpdateHandler = { (newState) in
            switch (newState) {
            case .ready:
                self.timeoutHandler?.cancel()
                self.connection?.stateUpdateHandler = nil
                self.onDataReceived(connection: self.connection!)
                self.connected = true
                self.flush()
                return
            case .setup:
                break
            case .waiting(_):
                self.disconnect(error: "connection waiting")
                return
            case .preparing:
                 break
            case .cancelled:
                self.disconnect(error: "connection canceled")
                return
            case .failed(_):
                self.disconnect(error: "connection failed")
                return
            @unknown default:
                break
            }
        }
        connection?.start(queue: thread)
    }
    
    public func disconnect(error: String? = nil) {
        connection?.stateUpdateHandler = nil
        connection?.forceCancel()
        connection = nil
        inputBuffer.removeAll(keepingCapacity: false)
        outputBuffer.removeAll(keepingCapacity: false)
        if connected && error != nil {
            self.callback?.onSocketError(error: error!)
        }
        connected = false
        semaphore.signal()
    }

    public func write(buffer: [UInt8]) throws {
        let data = Data(buffer)
        try write(data: data)
    }

    public func write(data: Data) throws {
        outputBuffer.append(data)
    }
    
    public func flush() {
        if !connected {
            return
        }
        let data = outputBuffer
        let count = data.count
        if !data.isEmpty && count > 0 {
            outputBuffer.removeFirst(count)
            connection?.send(content: data, completion: .contentProcessed { error in
                if error != nil {
                    self.disconnect(error: "write error")
                }
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
            let result = semaphore.wait(timeout: .now() + .seconds(5))
            if result == DispatchTimeoutResult.success && connected {
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
            let result = semaphore.wait(timeout: .now() + .seconds(5))
            if result == DispatchTimeoutResult.success && connected {
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
