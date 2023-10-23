//
// Created by Pedro  on 24/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation
import AVFoundation

public enum CameraHelper {
    public enum Facing {
        case BACK
        case FRONT
    }

    public enum Resolution {
        case cif352x288
        case vga640x480
        case hd1280x720
        case fhd1920x1080
        case fhd1920x1440
        case uhd3840x2160

        var width: Int {
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

        var height: Int {
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

        var value: AVCaptureSession.Preset {
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
    }
}
