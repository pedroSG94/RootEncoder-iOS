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
                print(newState)
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
        let sync = DispatchGroup()
        sync.enter()
        connection?.send(content: data, completion: NWConnection.SendCompletion.contentProcessed(( { NWError in
            if (NWError != nil) {
                print("error: \(NWError)")
                self.callback.onConnectionFailedRtsp(reason: "write packet error")
            }
            sync.leave()
        })))
        sync.wait()
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
        connection?.receiveMessage { (data, context, isComplete, error) in
            if (data != nil) {
                let message = String(data: data!, encoding: String.Encoding.utf8)!
                result = message
            }
            sync.leave()
        }
        sync.wait()
        return result
    }
}
