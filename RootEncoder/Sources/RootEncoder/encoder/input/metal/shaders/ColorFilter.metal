//
//  ColorFilter.metal
//  RootEncoder
//
//  Ported from Android color_fragment.glsl
//  Concatenated after FilterVertex.metal at runtime.
//

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float3 &uColor [[buffer(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    const float3 luma = float3(0.299, 0.587, 0.114);
    float4 pixel = tex.sample(s, data.uv);
    float grey = dot(pixel.rgb, luma);
    return float4(grey * uColor, pixel.a);
}
