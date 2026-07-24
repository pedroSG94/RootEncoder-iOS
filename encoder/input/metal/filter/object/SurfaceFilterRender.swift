//
//  Created by Pedro  on 24/07/26.
//

import common
import Foundation
import CoreImage
import CoreMedia
import QuartzCore
import AVFoundation

public class SurfaceFilterRender: BaseObjectFilterRender {

    private var player: AVPlayer? = nil
    private var videoOutput: AVPlayerItemVideoOutput? = nil
    private var loopObserver: NSObjectProtocol? = nil

    public override func draw(image: CIImage, orientation: CGImagePropertyOrientation, isPreview: Bool) -> CIImage {
        if let videoOutput = videoOutput {
            let itemTime = videoOutput.itemTime(forHostTime: CACurrentMediaTime())
            if videoOutput.hasNewPixelBuffer(forItemTime: itemTime),
               let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: nil) {
                write(pixelBuffer: pixelBuffer)
            }
        }
        return super.draw(image: image, orientation: orientation, isPreview: isPreview)
    }

    /**
     * Render the player video into the filter. The filter keeps a reference of the player until release or removePlayer called
     */
    public func setPlayer(player: AVPlayer, looping: Bool = false) {
        removePlayer()
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: attributes)
        player.currentItem?.add(videoOutput)
        if looping {
            loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main
            ) { [weak player] _ in
                player?.seek(to: .zero)
                player?.play()
            }
        }
        self.videoOutput = videoOutput
        self.player = player
    }

    public func removePlayer() {
        if let loopObserver = loopObserver { NotificationCenter.default.removeObserver(loopObserver) }
        loopObserver = nil
        if let videoOutput = videoOutput { player?.currentItem?.remove(videoOutput) }
        videoOutput = nil
        player = nil
    }

    /**
     * Render frames from any producer into the filter. For example another camera or a video decoder
     */
    public func write(pixelBuffer: CVPixelBuffer) {
        setObject(image: CIImage(cvPixelBuffer: pixelBuffer))
    }

    public func write(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        write(pixelBuffer: pixelBuffer)
    }

    public override func release() {
        removePlayer()
        super.release()
    }
}
