inline float noiseHash(float2 p) {
    p = fract(p * 0.3183099) * 50.0;
    return fract(p.x * p.y * (p.x + p.y));
}

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &uTime [[buffer(0)]],
                               constant float &uStrength [[buffer(1)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 seed = data.uv * 100.0 + uTime;
    float r = noiseHash(seed) * 0.01 - 0.005;
    return tex.sample(s, data.uv) + float4(r) * uStrength;
}
