import UIKit
import Main_Sources


let host = "192.168.0.32"
let port = 554

let socket = Socket(host: host, port: port)
print("socket initialized")
socket.connect()
print("socket connected")
let options = "OPTIONS rtsp://\(host):\(port)/live/pedro RTSP/1.0\r\nCSeq: 0\r\n\r\n"
socket.write(data: options)
print("socket write data: \(options)")
let response = socket.readBlock(blockTime: 1000)
print("socket response: \(response)")
socket.disconnect()
print("socket disconnected")
