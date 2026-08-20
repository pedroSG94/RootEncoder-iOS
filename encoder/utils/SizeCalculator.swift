//
//  SizeCalculator.swift
//  encoder
//
//  Created by Pedro  on 4/11/23.
//

import common
import Foundation
import MetalKit


public class SizeCalculator {
    
    public init() { }
    
    public static func processMatrix(initialOrientation: Int, currentOrientation: Int) -> CGImagePropertyOrientation {
        let degrees = (currentOrientation - initialOrientation + 360) % 360
        switch degrees {
        case 90:
            return .left
        case 180:
            return .down
        case 270:
            return .right
        default:
            return .up
        }
    }

    public static func getViewPort(mode: AspectRatioMode, streamWidth: CGFloat, streamHeight: CGFloat, previewWidth: CGFloat, previewHeight: CGFloat) -> MetalViewport  {
        if mode == AspectRatioMode.NONE {
            let positionX: CGFloat = 0
            let positionY: CGFloat = 0
            let scaleX = previewWidth / streamWidth
            let scaleY = previewHeight / streamHeight
            return MetalViewport(positionX: positionX, positionY: positionY, scaleX: scaleX, scaleY: scaleY)
        }
        let streamAspectRatio = streamWidth / streamHeight;
        let previewAspectRatio = previewWidth / previewHeight;
        var xo: CGFloat = 0;
        var yo: CGFloat = 0;
        var xf: CGFloat = previewWidth;
        var yf: CGFloat = previewHeight;
        if mode == AspectRatioMode.ADJUST {
            if streamAspectRatio > previewAspectRatio {
                yf = streamHeight * previewWidth / streamWidth;
                yo = (yf - previewHeight) / -2;
            } else {
                xf = streamWidth * previewHeight / streamHeight;
                xo = (xf - previewWidth) / -2;
            }
        } else { //AspectRatioMode.FILL
            if streamAspectRatio > previewAspectRatio {
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
    }
}
