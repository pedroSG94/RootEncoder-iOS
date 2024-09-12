//
//  File.swift
//  
//
//  Created by Pedro  on 12/9/24.
//

import Foundation

public class UrlParser {
    
    private(set) var scheme: String = ""
    private(set) var host: String = ""
    private(set) var port: Int? = nil
    private(set) var path: String = ""
    private(set) var query: String? = nil
    private(set) var authUser: String? = nil
    private(set) var authPassword: String? = nil
    private let url: String
    
    private init(uri: URL, url: String) {
        self.url = url
        let url = uri.absoluteString
        scheme = uri.scheme!
        host = uri.host!
        port = if uri.port != nil && uri.port! > 0 { uri.port } else { nil }
        path = uri.path.removePrefix(regex: "/")
        if uri.query != nil {
            let i: String.Index = url.range(of: uri.query!)?.lowerBound ?? String.Index(utf16Offset: 0, in: url)
            query = String(url[i...])
        }
        authUser = uri.user
        authPassword = uri.password
    }
    
    public static func parse(endpoint: String, requiredProtocols: [String]) throws -> UrlParser {
        guard let uri = URL(string: endpoint) else {
            throw UriParseException.runtimeError("Error creating URL")
        }
        if uri.scheme == nil || uri.host == nil {
            throw UriParseException.runtimeError("Invalid null scheme or host")
        }
        if !requiredProtocols.contains(uri.scheme!) {
            throw UriParseException.runtimeError("Invalid protocol: \(uri.scheme!)")
        }
        return UrlParser(uri: uri, url: endpoint)
    }
    
    public func getQuery(key: String) -> String? {
        return getAllQueries()[key]
    }
    
    public func getAppName() -> String {
        let fullPath = getFullPath()
        let indexes = fullPath.indexes(char: "/")
        let startIndex = String.Index(utf16Offset: 0, in: fullPath)
        switch indexes.count {
        case 0:
            return fullPath
        case 1:
            return String(fullPath[startIndex..<indexes[0]])
        default:
            if getAllQueries().isEmpty {
                return String(fullPath[startIndex..<indexes[1]])
            } else {
                return String(fullPath[startIndex..<indexes[0]])
            }
        }
    }
    
    public func getStreamName() -> String {
        return getFullPath().removePrefix(regex: getAppName()).removePrefix(regex: "/")
    }
    
    public func getTcUrl() -> String {
        let port = if port != nil { ":\(String(port!))" } else { "" }
        let appName = if !getAppName().isEmpty { "/\(getAppName())" } else { "" }
        return "\(scheme)://\(host)\(port)\(appName)"
    }
    
    public func getFullPath() -> String {
        let query = if query == nil { "" } else { "?\(query!)" }
        let fullPath = "\(path)\(query)".removePrefix(regex: "?")
        if (fullPath.isEmpty) {
            let port = if port != nil { ":\(port!)" } else { "" }
            return url.removePrefix(regex: "\(scheme)://\(host)\(port)").removePrefix(regex: "/")
        }
        return fullPath
    }
    
    private func getAllQueries() -> [String : String] {
        let queries = query?.split(separator: "&") ?? [Substring]()
        var map = [String : String]()
        queries.forEach { entry in
            let data = entry.split(separator: "=", maxSplits: 2)
            if data.count == 2 {
                map[String(data[0])] = String(data[1])
            }
        }
        return map
    }
}

public enum UriParseException: Error {
    case runtimeError(String)
}

