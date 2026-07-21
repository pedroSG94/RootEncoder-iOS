fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &intensity [[buffer(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float4 color = tex.sample(s, data.uv);
    float dist = distance(data.uv, float2(0.5, 0.5));
    float vignette = clamp(1.0 - dist * intensity, 0.0, 1.0);
    return float4(color.rgb * vignette, color.a);
}
