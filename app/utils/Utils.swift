//
//  Utils.swift
//  app
//
//  Created by Pedro  on 11/3/24.
//  Copyright © 2024 pedroSG94. All rights reserved.
//

import Foundation
import Photos
import SwiftUI

func getVideoUrl() -> URL? {
    let currentDate = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let fileName = "\(dateFormatter.string(from: currentDate)).mp4"
    
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        print("Error: No acess to document folder")
        return nil
    }
    let outputURL = documentsDirectory.appendingPathComponent(fileName)
    return outputURL
}

func saveVideoToGallery(videoURL: URL) {
    PHPhotoLibrary.requestAuthorization { status in
        guard status == .authorized else {
            return
        }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }) { success, error in
            if success {
                print("Video saved correctly.")
            } else {
                print("Error saving video: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
