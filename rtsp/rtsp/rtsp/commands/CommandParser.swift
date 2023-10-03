//
//  CommandParser.swift
//  rtsp
//
//  Created by Pedro  on 3/10/23.
//

import Foundation

class CommandParser {
    
    func loadServerPorts(command: Command, protocol: Protocol, audioClientPorts: [Int], videoClientPorts: [Int], audioServerPorts: inout [Int], videoServerPorts: inout [Int]) -> Bool {
        var isAudio = true
        if command.method == Method.SETUP && `protocol` == Protocol.UDP {
            let clientPattern = try! NSRegularExpression(pattern: "client_port=([0-9]+)-([0-9]+)")
            if let clientMatch = clientPattern.firstMatch(in: command.text, range: NSRange(command.text.startIndex..., in: command.text)) {
                let portStart = Int((command.text as NSString).substring(with: clientMatch.range(at: 1))) ?? -1
                isAudio = portStart == audioClientPorts[0]
            }
                
            let serverPattern = try! NSRegularExpression(pattern: "server_port=([0-9]+)-([0-9]+)")
            if let serverMatch = serverPattern.firstMatch(in: command.text, range: NSRange(command.text.startIndex..., in: command.text)) {
                if isAudio {
                    audioServerPorts[0] = Int((command.text as NSString).substring(with: serverMatch.range(at: 1))) ?? audioClientPorts[0]
                    audioServerPorts[1] = Int((command.text as NSString).substring(with: serverMatch.range(at: 2))) ?? audioClientPorts[1]
                } else {
                    videoServerPorts[0] = Int((command.text as NSString).substring(with: serverMatch.range(at: 1))) ?? videoClientPorts[0]
                    videoServerPorts[1] = Int((command.text as NSString).substring(with: serverMatch.range(at: 2))) ?? videoClientPorts[1]
                }
                return true
            }
        }
        return false
    }
        
    func getSessionId(command: Command) -> String {
        let rtspPattern = try! NSRegularExpression(pattern: "Session:(\\s?[^;\\n]+)")
        if let match = rtspPattern.firstMatch(in: command.text, range: NSRange(command.text.startIndex..., in: command.text)) {
            var sessionId = (command.text as NSString).substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
            if let tempRange = sessionId.range(of: ";") {
                sessionId = String(sessionId[..<tempRange.lowerBound])
            }
            return sessionId
        }
        return ""
    }
        
    func parseResponse(method: Method, responseText: String) -> Command {
        let status = getResponseStatus(response: responseText)
        let cSeq = getCSeq(request: responseText)
        return Command(method: method, cSeq: cSeq, status: status, text: responseText)
    }
        
    func parseCommand(commandText: String) -> Command {
        let method = getMethod(response: commandText)
        let cSeq = getCSeq(request: commandText)
        return Command(method: method, cSeq: cSeq, status: -1, text: commandText)
    }
        
    private func getCSeq(request: String) -> Int {
        let cSeqPattern = try! NSRegularExpression(pattern: "CSeq\\s*:\\s*(\\d+)", options: .caseInsensitive)
        if let match = cSeqPattern.firstMatch(in: request, range: NSRange(request.startIndex..., in: request)) {
            return Int((request as NSString).substring(with: match.range(at: 1))) ?? -1
        } else {
            print("cSeq not found")
            return -1
        }
    }
        
    private func getMethod(response: String) -> Method {
        let methodPattern = try! NSRegularExpression(pattern: "(\\w+) (\\S+) RTSP", options: .caseInsensitive)
        if let match = methodPattern.firstMatch(in: response, range: NSRange(response.startIndex..., in: response)) {
            if let methodRange = Range(match.range(at: 1), in: response) {
                let method = String(response[methodRange]).uppercased()
                switch method {
                    case Method.OPTIONS.rawValue:
                        return Method.OPTIONS
                    case Method.ANNOUNCE.rawValue:
                        return Method.ANNOUNCE
                    case Method.RECORD.rawValue:
                        return Method.RECORD
                    case Method.SETUP.rawValue:
                        return Method.SETUP
                    case Method.DESCRIBE.rawValue:
                        return Method.DESCRIBE
                    case Method.TEARDOWN.rawValue:
                        return Method.TEARDOWN
                    case Method.PLAY.rawValue:
                        return Method.PLAY
                    case Method.PAUSE.rawValue:
                        return Method.PAUSE
                    case Method.SET_PARAMETERS.rawValue:
                        return Method.SET_PARAMETERS
                    case Method.GET_PARAMETERS.rawValue:
                        return Method.GET_PARAMETERS
                    case Method.REDIRECT.rawValue:
                        return Method.REDIRECT
                    default:
                        return Method.UNKNOWN
                }
            }
        }
        return Method.UNKNOWN
    }
        
    private func getResponseStatus(response: String) -> Int {
        let statusPattern = try! NSRegularExpression(pattern: "RTSP/\\d.\\d (\\d+) (\\w+)", options: .caseInsensitive)
        if let match = statusPattern.firstMatch(in: response, range: NSRange(response.startIndex..., in: response)) {
            return Int((response as NSString).substring(with: match.range(at: 1))) ?? -1
        } else {
            print("status code not found")
            return -1
        }
    }
}
