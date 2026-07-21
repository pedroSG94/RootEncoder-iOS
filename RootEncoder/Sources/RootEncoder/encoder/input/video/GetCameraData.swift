//
//  GetCameraData.swift
//  app
//
//  Created by Pedro  on 16/5/21.
//  Copyright © 2021 pedroSG94. All rights reserved.
//

import Common
import Foundation
import AVFoundation


public protocol GetCameraData {
    func getYUVData(from buffer: CMSampleBuffer)
}
