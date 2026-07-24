fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &uTime [[buffer(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float waveu = sin((data.uv.y + uTime) * 20.0) * 0.5 * 0.05 * 0.3;
    return tex.sample(s, data.uv + float2(waveu, 0.0));
}
