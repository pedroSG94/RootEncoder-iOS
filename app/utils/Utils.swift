//
//  Utils.swift
//  app
//
//  Created by Pedro  on 11/3/24.
//  Copyright © 2024 pedroSG94. All rights reserved.
//

import Foundation
import Photos

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
