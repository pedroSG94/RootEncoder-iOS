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
}
