//
//  AuthUtil.swift
//  rtmp
//
//  Created by Pedro  on 23/4/24.
//

import Foundation

public class AuthUtil {
    
    public static func getAdobeAuthUserResult(user: String, password: String, salt: String, challenge: String, opaque: String) -> String {
        let challenge2 = String(format: "%08x", Int.random(in: Int.min...Int.max))
        var response = (user + salt + password).md5Base64
        if !opaque.isEmpty {
            response += opaque
        } else if !challenge.isEmpty {
            response += challenge
        }
        response = (response + challenge2).md5Base64
        var result = "?authmod=adobe&user=\(user)&challenge=\(challenge2)&response=\(response)"
        if !opaque.isEmpty {
            result += "&opaque=\(opaque)"
        }
        return result
    }
    
    public static func getSalt(description: String) -> String {
        return findDescriptionValue(value: "salt=", description: description)
    }
    
    public static func getChallenge(description: String) -> String {
        return findDescriptionValue(value: "challenge=", description: description)
    }
    
    public static func getOpaque(description: String) -> String {
        return findDescriptionValue(value: "opaque=", description: description)
    }
    
    public static func getLlnwAuthUserResult(user: String, password: String, nonce: String, app: String) -> String {
        let authMod = "llnw"
        let realm = "live"
        let method = "publish"
        let qop = "auth"
        let ncHex = String(format: "%08x", 1)
        let cNonce = String(format: "%08x", Int.random(in: Int.min...Int.max))
        var path = app
        //extract query parameters
        if let queryPos = path.firstIndex(of: "?") {
            path = String(path[..<queryPos])
        }
        if !path.contains("/") {
            path += "/_definst_"
        }
        let hash1 = "\(user):\(realm):\(password)".md5
        let hash2 = "\(method):/\(path)".md5
        let hash3 = "\(hash1):\(nonce):\(ncHex):\(cNonce):\(qop):\(hash2)".md5
        return "?authmod=\(authMod)&user=\(user)&nonce=\(nonce)&cnonce=\(cNonce)&nc=\(ncHex)&response=\(hash3)"
    }
    
    public static func getNonce(description: String) -> String {
        return findDescriptionValue(value: "nonce=", description: description)
    }
    
    private static func findDescriptionValue(value: String, description: String) -> String {
        var result = ""
        let data = description.split(separator: "&")
        for s in data {
            if s.contains(value) {
                result = String(s.dropFirst(value.count))
                break
            }
        }
        return result
    }
}
