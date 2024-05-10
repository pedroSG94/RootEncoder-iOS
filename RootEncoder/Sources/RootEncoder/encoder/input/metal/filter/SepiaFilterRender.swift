//
//  SepiaFilterRender.swift
//  encoder
//
//  Created by Pedro  on 5/4/24.
//

import Foundation
import CoreImage

public class SepiaFilterRender: BaseFilterRender {
    
    private let filter = CIFilter(name: "CISepiaTone")
    
    public init() {}
    
    public func draw(image: CIImage) -> CIImage {
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(1.0, forKey: kCIInputIntensityKey)
        return filter?.outputImage ?? image
    }
}
