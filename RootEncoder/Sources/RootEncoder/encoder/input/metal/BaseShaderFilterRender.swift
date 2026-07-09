//
//  BaseShaderFilterRender.swift
//  RootEncoder
//
//  Created by Pedro  on 8/7/25.
//

import Foundation
import CoreImage
import Metal


open class BaseShaderFilterRender: BaseFilterRender {
    
    private var context: CIContext? = nil
    private var commandQueue: MTLCommandQueue? = nil
    private let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    private var pipelineState: MTLRenderPipelineState? = nil
    private var inputTexture: MTLTexture? = nil
    private var outputTexturePreview: MTLTexture? = nil
    private var outputTextureOutput: MTLTexture? = nil

    public override func setMetalInfo(commandQueue: any MTLCommandQueue, context: CIContext) {
        self.commandQueue = commandQueue
        self.context = context
    }
    
    public override func initMetal(width: Int, height: Int, device: MTLDevice) {
        do {
            let library = try device.makeLibrary(source: initMetalFilter(), options: nil)
            guard let vertexFunction = library.makeFunction(name: "vertexFilter"),
                  let fragmentFunction = library.makeFunction(name: "fragmentFilter") else {
                fatalError("vertexFilter or fragmentFilter functions not found")
            }
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            self.pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
            self.inputTexture = MetalUtils.getTexture(device: device, texture: &inputTexture, width: width, height: height)
            self.outputTexturePreview = MetalUtils.getTexture(device: device, texture: &outputTexturePreview, width: width, height: height)
            self.outputTextureOutput = MetalUtils.getTexture(device: device, texture: &outputTextureOutput, width: width, height: height)
        } catch {
            fatalError("Shader compilation failed: \(error)")
        }
    }

    public override func draw(image: CIImage, orientation: CGImagePropertyOrientation, isPreview: Bool) -> CIImage {
        let outputTexture = if isPreview { outputTexturePreview } else { outputTextureOutput }
        guard let pipelineState = pipelineState,
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let context = context,
              let input = inputTexture,
              let output = outputTexture else { return image }
        
        context.render(image, to: input, commandBuffer: commandBuffer, bounds: image.extent, colorSpace: colorSpace)

        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = output
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return image }
        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentTexture(input, index: 0)
        drawFilter(encoder: encoder)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        commandBuffer.commit()

        guard let result = CIImage(mtlTexture: output, options: [.colorSpace: colorSpace]) else { return image }
        return result
    }
    
    open func initMetalFilter() -> String {
        fatalError("initMetalFilter error, add vertex and fragment is necessary")
    }

    open func drawFilter(encoder: MTLRenderCommandEncoder) {}
}
