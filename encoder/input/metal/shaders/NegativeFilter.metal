fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float3 negative = 1.0 - tex.sample(s, data.uv).rgb;
    return float4(negative, 1.0);
}
