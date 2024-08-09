//
//  GetH264Data.swift
//  app
//
//  Created by Pedro  on 16/5/21.
//  Copyright © 2021 pedroSG94. All rights reserved.
//

import Foundation
import CoreMedia

public protocol GetVideoData {
    
    func getVideoData(frame: Frame)
    
    func onVideoInfo(sps: Array<UInt8>, pps: Array<UInt8>, vps: Array<UInt8>?)
}
