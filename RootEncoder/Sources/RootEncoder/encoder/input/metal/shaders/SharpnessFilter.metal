fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float2 &uResolution [[buffer(0)]],
                               constant float &uSharpness [[buffer(1)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float4 up = tex.sample(s, data.uv + float2(0, 1) / uResolution);
    float4 left = tex.sample(s, data.uv + float2(-1, 0) / uResolution);
    float4 center = tex.sample(s, data.uv);
    float4 right = tex.sample(s, data.uv + float2(1, 0) / uResolution);
    float4 down = tex.sample(s, data.uv + float2(0, -1) / uResolution);

    return (1.0 + 4.0 * uSharpness) * center - uSharpness * (up + left + right + down);
}
