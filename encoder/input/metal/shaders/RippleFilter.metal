fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float2 &uResolution [[buffer(0)]],
                               constant float &uSpeed [[buffer(1)]],
                               constant float &uTime [[buffer(2)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 cPos = -1.0 + 2.0 * data.uv;
    float ratio = uResolution.x / uResolution.y;
    cPos.x *= ratio;
    float cLength = length(cPos);
    float2 uv = data.uv + (cPos / cLength) * cos(cLength * uSpeed - uTime * uSpeed) * 0.03;
    return tex.sample(s, uv);
}
