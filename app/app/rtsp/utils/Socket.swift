import Foundation
import Network

public class Socket: NSObject, StreamDelegate {
    private var callback: ConnectCheckerRtsp
    private var connection: NWConnection? = nil

    public init(host: String, port: Int, callback: ConnectCheckerRtsp) {
        self.callback = callback
        connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port("\(port)")!, using: .tcp)
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
    
    public func read() -> String {
        var result = ""
        let sync = DispatchGroup()
        sync.enter()
        if #available(iOS 14.0, *) {
            connection?.receiveDiscontiguous(minimumIncompleteLength: 1, maximumLength: 65536, completion: { data, context, isComplete, error in
                if let data = data {
                    let message = String(data: Data(data), encoding: String.Encoding.utf8)!
                    print(message)
                    result = message
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
