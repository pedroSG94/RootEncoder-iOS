#include <metal_stdlib>
using namespace metal;

struct FilterData {
    float4 position [[position]];
    float2 uv;
};

//GLSL style mod (uses floor). Metal fmod truncates toward zero and differs with negative values
inline float glslMod(float x, float y) { return x - y * floor(x / y); }
inline float2 glslMod(float2 x, float y) { return x - y * floor(x / y); }
inline float3 glslMod(float3 x, float y) { return x - y * floor(x / y); }
inline float4 glslMod(float4 x, float y) { return x - y * floor(x / y); }

vertex FilterData vertexFilter(uint id [[vertex_id]]) {
    const float2 vertices[4] = { float2(-1, -1), float2(1, -1), float2(-1, 1), float2(1, 1) };
    FilterData data;
    data.position = float4(vertices[id], 0, 1);
    data.uv = float2((vertices[id].x + 1) / 2, (1 - vertices[id].y) / 2);
    return data;
}
