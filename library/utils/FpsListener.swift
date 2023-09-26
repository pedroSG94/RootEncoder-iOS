//
// Created by Pedro  on 28/9/21.
// Copyright (c) 2021 pedroSG94. All rights reserved.
//

import Foundation

public class FpsListener {

   private var fps = 0
    private var time: Int64 = Int64(Date().timeIntervalSince1970)
   private var callback: FpsCallback?

   public func setCallback(callback: FpsCallback) {
      self.callback = callback
   }

   public func calculateFps() {
       if (Int64(Date().timeIntervalSince1970) - time > 1000) {
         callback?.onFps(fps: fps)
         fps = 0
           time = Int64(Date().timeIntervalSince1970)
      }
   }
}

public protocol FpsCallback {
   func onFps(fps: Int)
}
