//
//  AuthUtils.swift
//  rtmp
//
//  Created by Pedro  on 23/4/24.
//

import Foundation

public class AuthUtil {
    
    public static func getAdobeAuthUserResult(user: String, password: String, salt: String, challenge: String, opaque: String) -> String {
        return ""
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
        return ""
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
