import Foundation
import Network

public class Socket: NSObject, StreamDelegate {
    var callback: ConnectCheckerRtsp
    var host: String?
    private var connection: NWConnection? = nil

    /**
        TCP or TCP/TLS socket
     */
    public init(tlsEnabled: Bool, host: String, port: Int, callback: ConnectCheckerRtsp) {
        self.callback = callback
        self.host = host
        let parameters: NWParameters = tlsEnabled ? .tls : .tcp
        connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port("\(port)")!, using: parameters)
    }

    /**
        UDP socket
    */
    public init(host: String, localPort: Int, port: Int, callback: ConnectCheckerRtsp) {
        self.callback = callback
        self.host = host
        let localEndpoint = NWEndpoint.hostPort(host: "0.0.0.0", port: NWEndpoint.Port("\(localPort)")!)
        let parameters = NWParameters.udp
        parameters.requiredLocalEndpoint = localEndpoint
        connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port("\(port)")!, using: parameters)
    }
    
    public func connect() {
        let sync = DispatchGroup()
        sync.enter()
        connection?.stateUpdateHandler = { (newState) in
            switch (newState) {
            case .ready:
                print("connection success")
                sync.leave()
                break
            case .setup:
                print("setup")
                break
            case .waiting(_):
                print("waiting")
                break
            case .preparing:
                print("preparing")
                 break
            case .cancelled:
                print("cacelled")
                self.callback.onConnectionFailedRtsp(reason: "connection cancelled")
            case .failed(_):
                print("failed")
                self.callback.onConnectionFailedRtsp(reason: "connection failed")
                break
            @unknown default:
                print("new state: \(newState)")
                break
            }
        }
        connection?.start(queue: .main)
        sync.wait()
    }
    
    public func disconnect() {
        connection?.forceCancel()
        connection = nil
    }

    public func write(buffer: [UInt8]) {
        let data = Data(buffer)
        write(data: data)
    }

    public func write(data: Data) {
        connection?.send(content: data, completion: NWConnection.SendCompletion.contentProcessed(( { error in
            if (error != nil) {
                print("error: \(error)")
                self.callback.onConnectionFailedRtsp(reason: "write packet error")
            }
        })))
    }

    public func write(buffer: [UInt8], size: Int) {
        let data = Data(bytes: buffer, count: size)
        write(data: data)
    }
    
    public func write(data: String) {
        print("\(data)")
        let buffer = [UInt8](data.utf8)
        self.write(buffer: buffer)
    }

    public func read() -> [UInt8] {
        let data: Data = read()
        return [UInt8](data)
    }

    public func readString() -> String {
        let data: Data = read()
        let message = String(data: data, encoding: String.Encoding.utf8)!
        print(message)
        return message
    }

    public func read() -> Data {
        readUntil(length: 65536)
    }

    public func readUntil(length: Int) -> [UInt8] {
        let data: Data = readUntil(length: length)
        return [UInt8](data)
    }

    private func readUntil(length: Int) -> Data {
        var result = Data()
        let sync = DispatchGroup()
        sync.enter()
        if #available(iOS 14.0, *) {
            connection?.receiveDiscontiguous(minimumIncompleteLength: 1, maximumLength: length, completion: { data, context, isComplete, error in
                if let data = data {
                    result = Data(data)
                }
                if let error = error {
                    self.callback.onConnectionFailedRtsp(reason: "fail to read \(error)")
                }
                if isComplete {
                    self.callback.onConnectionFailedRtsp(reason: "fail to read EOF")

                }
                sync.leave()
            })
        } else {
            // Fallback on earlier versions
        }
        sync.wait()
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
