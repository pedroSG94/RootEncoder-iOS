//
// Created by Pedro  on 24/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public class CameraHelper {
    
    public static func getCameraOrientation() -> Int {
        switch getOrientation() {
        case .portrait:
            return 90
        case .portraitUpsideDown:
            return 270
        case .landscapeLeft:
            return 0
        case .landscapeRight:
            return 180
        default:
            return 0
        }
    }
    
    public static func getOrientation() -> UIInterfaceOrientation {
        return UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .landscapeLeft
    }
    
    public enum Facing {
        case BACK
        case FRONT
    }
    
    public enum Resolution: CaseIterable {
        case cif352x288
        case vga640x480
        case hd1280x720
        case fhd1920x1080
        case fhd1920x1440
        case uhd3840x2160

        public var width: Int {
            switch self {
            case .cif352x288:
                 return 352
            case .vga640x480:
                return 640
            case .hd1280x720:
                return 1280
            case .fhd1920x1080:
                return 1920
            case .fhd1920x1440:
                return 1920
            case .uhd3840x2160:
                return 3840
            }
        }

        public var height: Int {
            switch self {
            case .cif352x288:
                return 288
            case .vga640x480:
                return 480
            case .hd1280x720:
                return 720
            case .fhd1920x1080:
                return 1080
            case .fhd1920x1440:
                return 1440
            case .uhd3840x2160:
                return 2160
            }
        }
        
        public var aspecRatio: Double {
            switch self {
            case .cif352x288:
                return 352 / 288
            case .vga640x480:
                return 640 / 800
            case .hd1280x720:
                return 1280 / 720
            case .fhd1920x1080:
                return 1920 / 1080
            case .fhd1920x1440:
                return 1920 / 1440
            case .uhd3840x2160:
                return 3840 / 2160
            }
        }
        
        public static func getOptimalResolution(width: Int, height: Int) throws -> Resolution {
            let r = CameraHelper.Resolution.getOptimalResolution(
                actualResolution: CMVideoDimensions(width: Int32(width), height: Int32(height))
            )
            for resolution in Resolution.allCases {
                if resolution.width == r.width && resolution.height == r.height {
                    return resolution
                }
            }
            throw IOException.runtimeError("This camera resolution can't be opened")
        }

        public var preset: AVCaptureSession.Preset {
            switch self {
            case .cif352x288:
                return .cif352x288
            case .vga640x480:
                return .vga640x480
            case .hd1280x720:
                return .hd1280x720
            case .fhd1920x1080:
                return .hd1920x1080
            case .fhd1920x1440:
                return .hd1920x1080
            case .uhd3840x2160:
                return .hd4K3840x2160
            }
        }
        
        private static func getOptimalResolution(actualResolution: CMVideoDimensions) -> CMVideoDimensions {
            let resolutionsSupported = CameraHelper.Resolution.allCases.map({
                CMVideoDimensions(width: Int32($0.width), height:  Int32($0.height))
            })
            if resolutionsSupported.contains(where: { $0.width == actualResolution.width && $0.height == actualResolution.height}) {
                return actualResolution
            } else {
                let actualAspectRatio = actualResolution.width / actualResolution.height
                var resolutions = resolutionsSupported.filter { $0.width / $0.height == actualAspectRatio }
                if (!resolutions.isEmpty) {
                    resolutions.append(actualResolution)
                    resolutions.sort(by: { $0.width + $0.height > $1.width + $1.height })
                    var index = 0
                    for (i, item) in resolutions.enumerated() {
                        if item.width == actualResolution.width && item.height == actualResolution.height {
                            index = i
                            break
                        }
                    }
                    if (index > 0) {
                        return resolutions[index - 1]
                    } else {
                        return resolutions[index + 1]
                    }
                } else {
                    return actualResolution
                }
            }
        }
    }
}
