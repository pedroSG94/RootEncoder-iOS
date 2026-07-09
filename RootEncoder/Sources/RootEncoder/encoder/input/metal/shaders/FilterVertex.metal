//
//  FilterVertex.metal
//  RootEncoder
//
//  Created by Pedro  on 8/7/25.
//
//  Default vertex function shared by shader filters. It draws a full screen quad
//  with uv coordinates using bottom-left as origin (OpenGL style).
//

#include <metal_stdlib>
using namespace metal;

struct FilterData {
    float4 position [[position]];
    float2 uv;
};

vertex FilterData vertexFilter(uint id [[vertex_id]]) {
    const float2 vertices[4] = { float2(-1, -1), float2(1, -1), float2(-1, 1), float2(1, 1) };
    FilterData data;
    data.position = float4(vertices[id], 0, 1);
    data.uv = float2((vertices[id].x + 1) / 2, (1 - vertices[id].y) / 2);
    return data;
}
