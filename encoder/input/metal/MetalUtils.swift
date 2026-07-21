//
//  MetalUtils.swift
//  RootEncoder
//
//  Created by Pedro  on 09/07/2026.
//
import common
import Metal

public class MetalUtils {
    public static func readShader(name: String) -> String {
        return readShader(name: name, bundle: Bundle.module)
    }

    public static func readShader(name: String, bundle: Bundle) -> String {
        guard let url = bundle.url(forResource: name, withExtension: "metal", subdirectory: "shaders")
                ?? bundle.url(forResource: name, withExtension: "metal") else {
            fatalError("compile metal file error, not found")
        }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }
    
    public static func getTexture(device: MTLDevice, texture: inout MTLTexture?, width: Int, height: Int) -> MTLTexture? {
        if let texture = texture, texture.width == width, texture.height == height { return texture }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
        descriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        texture = device.makeTexture(descriptor: descriptor)
        return texture
    }
}
