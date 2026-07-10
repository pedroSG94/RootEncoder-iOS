//
//  BlackFilterRender.swift
//  RootEncoder
//
//  Ported from Android BlackFilterRender
//

import Foundation
import Metal

public class BlackFilterRender: BaseShaderFilterRender {

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "BlackFilter")
    }
}
