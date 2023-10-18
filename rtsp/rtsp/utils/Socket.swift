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
    
    public func connect() throws {
        let sync = DispatchGroup()
        
        var messageError: String? = nil
        sync.enter()
        var shouldLeave = true
        connection?.stateUpdateHandler = { (newState) in
            switch (newState) {
            case .ready:
                print("connection success")
                if (shouldLeave) {
                    sync.leave()
                    shouldLeave = false
                }
                break
            case .setup:
                print("setup")
                break
            case .waiting(_):
                print("waiting")
                messageError = "connection failed"
                if (shouldLeave) {
                    sync.leave()
                    shouldLeave = false
                }
                break
            case .preparing:
                print("preparing")
                 break
            case .cancelled:
                print("cancelled")
                messageError = "connection cancelled"
                if (shouldLeave) {
                    sync.leave()
                    shouldLeave = false
                }
            case .failed(_):
                print("failed")
                messageError = "connection failed"
                if (shouldLeave) {
                    sync.leave()
                    shouldLeave = false
                }
                break
            @unknown default:
                print("new state: \(newState)")
                break
            }
        }
        connection?.start(queue: .global())
        sync.wait()
        if (messageError != nil) {
            throw IOException.runtimeError(messageError!)
        }
    }
    
    public func disconnect() {
        connection?.forceCancel()
        connection = nil
    }

    public func appendRead(buffer: [UInt8]) {
        bufferAppend = buffer
    }

    public func write(buffer: [UInt8]) throws {
        let data = Data(buffer)
        try write(data: data)
    }

    
    public func write(data: Data) throws {
        try lock.sync {
            let sync = DispatchGroup()
            var messageError: String? = nil
            sync.enter()
            connection?.send(content: data, completion: NWConnection.SendCompletion.contentProcessed(( { error in
                if (error != nil) {
                    print("error: \(error!)")
                    messageError = "write packet error"
                }
                sync.leave()
            })))
            sync.wait()
            if (messageError != nil) {
                throw IOException.runtimeError(messageError!)
            }
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
        var bytes = [UInt8](data)
        if (bufferAppend != nil) {
            bytes.insert(contentsOf: bufferAppend!, at: 0)
        }
        return bytes
    }

    public func readString() throws -> String {
        let data: Data = try read()
        let message = String(data: data, encoding: String.Encoding.utf8)!
        return message
    }

    public func read() throws -> Data {
        try readUntil(length: 65536)
    }

    public func readUntil(length: Int) throws -> [UInt8] {
        let data: Data = try readUntil(length: length)
        var bytes = [UInt8](data)
        if (bufferAppend != nil) {
            bytes.insert(contentsOf: bufferAppend!, at: 0)
        }
        return bytes
    }
    
    private func readUntil(length: Int) throws -> Data {
        try readLock.sync {
            var result = Data()
            var messageError: String? = nil
            let sync = DispatchGroup()
            sync.enter()
            connection?.receiveDiscontiguous(minimumIncompleteLength: 1, maximumLength: length, completion: { data, context, isComplete, error in
                if let data = data {
                    result = Data(data)
                } else if let error = error {
                    messageError = "fail to read \(error)"
                } else if isComplete {
                    messageError = "fail to read EOF"
                }
                
                sync.leave()
            })
            sync.wait()
            if (messageError != nil) {
                throw IOException.runtimeError(messageError!)
            }
            return result
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
