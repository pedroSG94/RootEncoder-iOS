//
//  NegativeFilterRender.swift
//  RootEncoder
//
//  Ported from Android NegativeFilterRender
//

import Foundation
import Metal

public class NegativeFilterRender: BaseShaderFilterRender {

    public override func initMetalFilter() -> String {
        return MetalUtils.readShader(name: "FilterVertex") + MetalUtils.readShader(name: "NegativeFilter")
    }
}
