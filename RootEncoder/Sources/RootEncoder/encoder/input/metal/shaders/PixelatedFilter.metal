//
//  PixelatedFilter.metal
//  RootEncoder
//
//  Ported from Android pixelated_fragment.glsl
//  Concatenated after FilterVertex.metal at runtime.
//

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &uPixelated [[buffer(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 coord = float2(uPixelated * floor(data.uv.x / uPixelated), uPixelated * floor(data.uv.y / uPixelated));
    return tex.sample(s, coord);
}
