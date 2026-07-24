fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &uTime [[buffer(0)]],
                               constant float2 &uResolution [[buffer(1)]],
                               constant float &uRadius [[buffer(2)]],
                               constant float2 &uCenter [[buffer(3)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    const float PI = 3.14159;
    float effectAngle = 2.0 * PI * uTime;
    float2 uv = data.uv - uCenter;
    float len = length(uv * float2(uResolution.x / uResolution.y, 1.0));
    float angle = atan2(uv.y, uv.x) + effectAngle * smoothstep(uRadius, 0.0, len);
    float radius = length(uv);

    return tex.sample(s, float2(radius * cos(angle), radius * sin(angle)) + uCenter);
}
