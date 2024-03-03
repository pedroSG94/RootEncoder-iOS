//
//  SizeCalculator.swift
//  encoder
//
//  Created by Pedro  on 4/11/23.
//

import Foundation
import MetalKit


public class SizeCalculator {
    
    public init() { }
    
    public static func processMatrix(initialOrientation: UIDeviceOrientation) -> CGImagePropertyOrientation {
        switch initialOrientation {
        case .landscapeLeft:
            switch UIDevice.current.orientation {
            case .landscapeLeft:
                return .up
            case .landscapeRight:
                return .down
            case .portrait:
                return .right
            case .portraitUpsideDown:
                return .left
            default:
                return .up
            }
        case .landscapeRight:
            switch UIDevice.current.orientation {
            case .landscapeLeft:
                return .down
            case .landscapeRight:
                return .up
            case .portrait:
                return .left
            case .portraitUpsideDown:
                return .right
            default:
                return .up
            }
        case .portrait:
            switch UIDevice.current.orientation {
            case .landscapeLeft:
                return .left
            case .landscapeRight:
                return .right
            case .portrait:
                return .up
            case .portraitUpsideDown:
                return .down
            default:
                return .up
            }
        case .portraitUpsideDown:
            switch UIDevice.current.orientation {
            case .landscapeLeft:
                return .right
            case .landscapeRight:
                return .left
            case .portrait:
                return .down
            case .portraitUpsideDown:
                return .up
            default:
                return .up
            }
        default:
            return .up
        }
    }
    
    public static func getViewPort(mode: AspectRatioMode, streamWidth: CGFloat, streamHeight: CGFloat, previewWidth: CGFloat, previewHeight: CGFloat) -> MetalViewport  {
        if (mode != AspectRatioMode.NONE) {
            let streamAspectRatio = streamWidth / streamHeight;
            let previewAspectRatio = previewWidth / previewHeight;
            var xo: CGFloat = 0;
            var yo: CGFloat = 0;
            var xf: CGFloat = previewWidth;
            var yf: CGFloat = previewHeight;
            if ((streamAspectRatio > 1 && previewAspectRatio > 1 && streamAspectRatio > previewAspectRatio) || (streamAspectRatio < 1 && previewAspectRatio < 1 && streamAspectRatio > previewAspectRatio) || (streamAspectRatio > 1 && previewAspectRatio < 1)) {
                if (mode == AspectRatioMode.ADJUST) {
                    yf = streamHeight * previewWidth / streamWidth;
                    yo = (yf - previewHeight) / -2;
                } else {
                    xf = streamWidth * previewHeight / streamHeight;
                    xo = (xf - previewWidth) / -2;
                }
            } else if ((streamAspectRatio > 1 && previewAspectRatio > 1 && streamAspectRatio < previewAspectRatio) || (streamAspectRatio < 1 && previewAspectRatio < 1 && streamAspectRatio < previewAspectRatio) || (streamAspectRatio < 1 && previewAspectRatio > 1)) {
                if (mode == AspectRatioMode.ADJUST) {
                    xf = streamWidth * previewHeight / streamHeight;
                    xo = (xf - previewWidth) / -2;
                } else {
                    yf = streamHeight * previewWidth / streamWidth;
                    yo = (yf - previewHeight) / -2;
                }
            }
            let scaleX = xf / streamWidth
            let scaleY = yf / streamHeight
            return MetalViewport(positionX: xo, positionY: yo, scaleX: scaleX, scaleY: scaleY)
        } else {
            let positionX: CGFloat = 0
            let positionY: CGFloat = 0
            let scaleX = previewWidth / streamWidth
            let scaleY = previewHeight / streamHeight
            return MetalViewport(positionX: positionX, positionY: positionY, scaleX: scaleX, scaleY: scaleY)
        }
    }
}
