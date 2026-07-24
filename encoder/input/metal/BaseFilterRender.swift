//
//  BaseFilterRender.swift
//  encoder
//
//  Created by Pedro  on 4/11/23.
//

import common
import Foundation
import CoreImage
import Metal


open class BaseFilterRender {
    
    public var renderMode = RenderMode.ALL
    private var context: CIContext? = nil
    private var commandQueue: MTLCommandQueue? = nil
    private var device: MTLDevice? = nil
    private let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    private var pipelineState: MTLRenderPipelineState? = nil
    private var inputTexture: MTLTexture? = nil
    private var outputTexturePreview: MTLTexture? = nil
    private var outputTextureOutput: MTLTexture? = nil
    public private(set) var resolution = SIMD2<Float>(640, 480)

    public init() { }
    
    public func setMetalInfo(commandQueue: any MTLCommandQueue, context: CIContext) {
        self.commandQueue = commandQueue
        self.context = context
    }
    
    public func initMetal(device: MTLDevice) {
        self.device = device
        guard let shader = initMetalFilter() else { return }
        do {
            let library = try device.makeLibrary(source: shader, options: nil)
            guard let vertexFunction = library.makeFunction(name: "vertexFilter"),
                  let fragmentFunction = library.makeFunction(name: "fragmentFilter") else {
                fatalError("vertexFilter or fragmentFilter functions not found")
            }
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            self.pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("Shader compilation failed: \(error)")
        }
    }

    public func draw(image: CIImage, orientation: CGImagePropertyOrientation, isPreview: Bool) -> CIImage {
        let width = Int(image.extent.width)
        let height = Int(image.extent.height)
        if width <= 0 || height <= 0 { return image }
        guard let pipelineState = pipelineState,
              let device = device,
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let context = context else { return image }
        resolution = SIMD2<Float>(Float(width), Float(height))
        let output: MTLTexture?
        if isPreview {
            output = MetalUtils.getTexture(device: device, texture: &outputTexturePreview, width: width, height: height)
        } else {
            output = MetalUtils.getTexture(device: device, texture: &outputTextureOutput, width: width, height: height)
        }
        guard let input = MetalUtils.getTexture(device: device, texture: &inputTexture, width: width, height: height),
              let output = output else { return image }

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
    
    open func initMetalFilter() -> String? {
        nil
    }

    open func drawFilter(encoder: MTLRenderCommandEncoder) {}
    
    open func release() {}
}

