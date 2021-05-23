import Foundation

public class Socket: NSObject, StreamDelegate {
    private var host: String
    private var port: Int
    private var inputQueue = DispatchQueue(label: "input", qos: .userInitiated)
    private var outputQueue = DispatchQueue(label: "output", qos: .userInitiated)
    var inputStream: InputStream?
    var outputStream: OutputStream?
    private var callback: ConnectCheckerRtsp
    
    public init(host: String, port: Int, callback: ConnectCheckerRtsp) {
        self.host = host
        self.port = port
        self.callback = callback
    }
    
    public func connect() {
        var readStream:  Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?

        CFStreamCreatePairWithSocketToHost(nil, self.host as CFString, UInt32(self.port), &readStream, &writeStream)

        self.inputStream = readStream!.takeRetainedValue()
        if let inputStream = inputStream {
            CFReadStreamSetDispatchQueue(inputStream, inputQueue)
        }
        self.outputStream = writeStream!.takeRetainedValue()
        if let outputStream = outputStream {
            CFWriteStreamSetDispatchQueue(outputStream, outputQueue)
        }

        self.inputStream?.delegate = self
        self.outputStream?.delegate = self

        self.inputStream?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        self.outputStream?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)

        self.inputStream?.open()
        self.outputStream?.open()
    }
    
    public func disconnect() {
        inputStream?.close()
        outputStream?.close()
        inputStream?.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
        outputStream?.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
        inputStream?.delegate = nil
        outputStream?.delegate = nil
        inputStream = nil
        outputStream = nil
    }
    
    public func write(buffer: [UInt8]) {
        outputQueue.async {
            let result = self.outputStream?.write(buffer, maxLength: buffer.count) ?? -1
            if (result <= 1) {
                print("write error")
                self.callback.onConnectionFailedRtsp(reason: "write packet failed")
            }
        }
    }
    
    public func write(data: String) {
        print("write: \(data)")
        let buffer = [UInt8](data.utf8)
        self.write(buffer: buffer)
    }
    
    public func readBlock(blockTime: Int64) -> String {
        let actualTime = Date().millisecondsSince1970
        var time = actualTime
        while (inputStream?.hasBytesAvailable == false || (time - actualTime) >= blockTime) {
            time = Date().millisecondsSince1970
            let sleepMillis = 10
            usleep(UInt32(sleepMillis * 1000))
        }
        let response = self.read()
        //print("read: \(response)")
        return response
    }
    
    public func read() -> String {
        var result = ""
        let bufferSize = 1024
        var buffer = Array<UInt8>(repeating: 0, count: 1024)
        var read: Int
        while (inputStream?.hasBytesAvailable)! {
            read = (inputStream?.read(&buffer, maxLength: bufferSize))!
            if read < 0 {
                //Stream error occured
                print("error: \(read)")
            } else if read == 0 {
                //EOF
                let output = String(bytes: buffer, encoding: .ascii)
                if nil != output {
                    result = result + output!
                }
                print("EOF")
                break
            }
            let output = String(bytes: buffer, encoding: .utf8)
            if nil != output {
                result = result + output!
            }
        }
        return result
    }
    
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        if aStream === inputStream {
            switch eventCode {
            case Stream.Event.errorOccurred:
                print("error input")
                break
            case Stream.Event.openCompleted:
                print("open input")
                break
            case Stream.Event.hasSpaceAvailable:
                print("scape input")
                break
            case Stream.Event.hasBytesAvailable:
                print("buffer input")
                break
            case Stream.Event.endEncountered:
                print("end input")
                break
            default:
                print("other input")
                break
            }
        } else if aStream == outputStream {
            switch eventCode {
            case Stream.Event.errorOccurred:
                print("error output")
                break
            case Stream.Event.openCompleted:
                print("open output")
                break
            case Stream.Event.hasSpaceAvailable:
                print("space output")
                break
            case Stream.Event.hasBytesAvailable:
                print("buffer output")
                break
            case Stream.Event.endEncountered:
                print("end output")
                break
            default:
                print("other output")
                break
            }
        }
    }
}
