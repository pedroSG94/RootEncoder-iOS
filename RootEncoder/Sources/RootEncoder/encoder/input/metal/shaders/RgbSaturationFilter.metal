//
//  RgbSaturationFilter.metal
//  RootEncoder
//
//  Ported from Android rgb_saturation_fragment.glsl
//  Concatenated after FilterVertex.metal at runtime.
//

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float3 &uRGBSaturation [[buffer(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float4 pixel = tex.sample(s, data.uv);
    return float4(pixel.r * uRGBSaturation.r, pixel.g * uRGBSaturation.g, pixel.b * uRGBSaturation.b, 1.0);
}
