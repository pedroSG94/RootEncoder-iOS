//
//  LamoishFilterRender.swift
//  RootEncoder
//
//  Ported from Android LamoishFilterRender
//

import Foundation
import Metal

public class LamoishFilterRender: BaseShaderFilterRender {

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "LamoishFilter")
    }
}
