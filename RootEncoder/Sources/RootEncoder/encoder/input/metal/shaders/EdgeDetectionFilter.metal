//
//  EdgeDetectionFilter.metal
//  RootEncoder
//
//  Ported from Android edge_detection_fragment.glsl
//  Concatenated after FilterVertex.metal at runtime.
//

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float4 color = tex.sample(s, data.uv);
    float gray = length(color.rgb);
    return float4(float3(step(0.06, length(float2(dfdx(gray), dfdy(gray))))), 1.0);
}
