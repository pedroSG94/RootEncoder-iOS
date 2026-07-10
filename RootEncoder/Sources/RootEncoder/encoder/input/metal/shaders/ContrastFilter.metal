//
//  ContrastFilter.metal
//  RootEncoder
//
//  Ported from Android contrast_fragment.glsl
//  Concatenated after FilterVertex.metal at runtime.
//

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &uContrast [[buffer(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float4 pixel = tex.sample(s, data.uv);
    return float4((pixel.rgb - float3(0.5)) * uContrast + float3(0.5), pixel.a);
}
