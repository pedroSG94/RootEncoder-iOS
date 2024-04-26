//
//  GreyScaleFilterRender.swift
//  encoder
//
//  Created by Pedro  on 4/11/23.
//

import Foundation
import CoreImage

public class GreyScaleFilterRender: BaseFilterRender {
    
    private let filter = CIFilter(name: "CIColorMonochrome")
    
    public init() {}
    
    public func draw(image: CIImage) -> CIImage {
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(CIColor(red: 0.75, green: 0.75, blue: 0.75), forKey: kCIInputColorKey)
        filter?.setValue(1.0, forKey: kCIInputIntensityKey)
        return filter?.outputImage ?? image
    }
}
