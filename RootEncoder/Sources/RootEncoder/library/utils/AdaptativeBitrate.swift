//
//  File.swift
//  RootEncoder
//
//  Created by Pedro  on 1/10/24.
//

import Foundation

public class AdaptativeBitrate {
    
    public protocol Listener {
        func onBitrateAdapted(bitrate: UInt64)
    }
    
    private var maxBitrate: UInt64 = 0
    private var oldBitrate: UInt64 = 0
    private var averageBitrate: UInt64 = 0
    private var cont = 0
    private let listener: Listener
    private var decreaseRange: Float = 0.8 //20%
    private var increaseRange: Float = 1.2 //20%
    
    public init(listener: Listener) {
        self.listener = listener
    }
    
    public func setMaxBitrate(bitrate: UInt64) {
        maxBitrate = bitrate
        oldBitrate = bitrate
        reset()
    }

    public func adaptBitrate(actualBitrate: UInt64) {
        averageBitrate += actualBitrate
        averageBitrate /= 2
        cont += 1
        if cont >= 5 {
          if maxBitrate != 0 {
              listener.onBitrateAdapted(bitrate: getBitrateAdapted(bitrate: averageBitrate))
              reset()
          }
        }
      }

      /**
       * Adapt bitrate on fly based on queue state.
       */
    public func adaptBitrate(actualBitrate: UInt64, hasCongestion: Bool) {
        averageBitrate += actualBitrate
        averageBitrate /= 2
        cont += 1
        if cont >= 5 {
          if maxBitrate != 0 {
              listener.onBitrateAdapted(bitrate: getBitrateAdapted(bitrate: averageBitrate, hasCongestion: hasCongestion))
              reset()
          }
        }
      }

    private func getBitrateAdapted(bitrate: UInt64) -> UInt64 {
        if bitrate >= maxBitrate { //You have high speed and max bitrate. Keep max speed
            oldBitrate = maxBitrate
        } else if Double(bitrate) <= Double(oldBitrate) * 0.9 { //You have low speed and bitrate too high. Reduce bitrate by 10%.
            oldBitrate = bitrate * UInt64(decreaseRange)
        } else { //You have high speed and bitrate too low. Increase bitrate by 10%.
            oldBitrate = bitrate * UInt64(increaseRange)
            if oldBitrate > maxBitrate { oldBitrate = maxBitrate }
        }
        return oldBitrate
      }

    private func getBitrateAdapted(bitrate: UInt64, hasCongestion: Bool) -> UInt64 {
        if bitrate >= maxBitrate { //You have high speed and max bitrate. Keep max speed
            oldBitrate = maxBitrate
        } else if hasCongestion { //You have low speed and bitrate too high. Reduce bitrate by 10%.
            oldBitrate = bitrate * UInt64(decreaseRange)
        } else { //You have high speed and bitrate too low. Increase bitrate by 10%.
            oldBitrate = bitrate * UInt64(increaseRange)
            if oldBitrate > maxBitrate { oldBitrate = maxBitrate }
        }
        return oldBitrate
      }

      public func reset() {
        averageBitrate = 0
        cont = 0
      }

    public func getDecreaseRange() -> Float {
        return decreaseRange
      }

      /**
       * @param decreaseRange in percent. How many bitrate will be reduced based on oldBitrate.
       * valid values:
       * 0 to 100 not included
       */
    public func setDecreaseRange(decreaseRange: Float) {
        if decreaseRange > 0.0 && decreaseRange < 100.0 {
            self.decreaseRange = 1.0 - (decreaseRange / 100.0)
        }
      }

      public func getIncreaseRange() -> Float {
          return increaseRange
      }

      /**
       * @param increaseRange in percent. How many bitrate will be increment based on oldBitrate.
       * valid values:
       * 0 to 100
       */
    public func setIncreaseRange(increaseRange: Float) {
        if increaseRange > 0.0 && increaseRange < 100.0 {
            self.increaseRange = 1.0 + (increaseRange / 100.0)
        }
      }
}
