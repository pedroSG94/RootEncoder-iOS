//
//  SizeCalculator.swift
//  encoder
//
//  Created by Pedro  on 4/11/23.
//

import Foundation

public class SizeCalculator {
    
    public init() { }
    
    public func getViewPort(mode: AspectRatioMode, streamWidth: CGFloat, streamHeight: CGFloat, previewWidth: CGFloat, previewHeight: CGFloat) -> MetalViewport  {
        if (mode != AspectRatioMode.NONE) {
            let streamAspectRatio = streamWidth / streamHeight;
            let previewAspectRatio = previewWidth / previewHeight;
            var xo: CGFloat = 0;
            var yo: CGFloat = 0;
            var xf: CGFloat = previewWidth;
            var yf: CGFloat = previewHeight;
            if ((streamAspectRatio > 1 && previewAspectRatio > 1 && streamAspectRatio > previewAspectRatio) || (streamAspectRatio < 1 && previewAspectRatio < 1 && streamAspectRatio > previewAspectRatio) || (streamAspectRatio > 1 && previewAspectRatio < 1)
            ) {
                if (mode == AspectRatioMode.ADJUST) {
                    yf = streamHeight * previewWidth / streamWidth;
                    yo = (yf - previewHeight) / -2;
                } else {
                    xf = streamWidth * previewHeight / streamHeight;
                    xo = (xf - previewWidth) / -2;
                }
            } else if ((streamAspectRatio > 1 && previewAspectRatio > 1 && streamAspectRatio < previewAspectRatio) || (streamAspectRatio < 1 && previewAspectRatio < 1 && streamAspectRatio < previewAspectRatio) || (streamAspectRatio < 1 && previewAspectRatio > 1)
            ) {
                if (mode == AspectRatioMode.ADJUST) {
                    xf = streamWidth * previewHeight / streamHeight;
                    xo = (xf - previewWidth) / -2;
                } else {
                    yf = streamHeight * previewWidth / streamWidth;
                    yo = (yf - previewHeight) / -2;
                }
            //aspect ratio 1:1
            } else {
                if (previewWidth < previewHeight) {
                    yf = xf;
                    yo = (previewHeight - xf) / 2;
                } else {
                    xf = yf;
                    xo = (previewWidth - yf) / 2;
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
