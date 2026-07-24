fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &uBlur [[buffer(0)]],
                               constant float &uRadius [[buffer(1)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float3 sum = float3(0.0);
    if (uBlur > 0.0) {
        for (float i = -uBlur; i < uBlur; i++) {
            for (float j = -uBlur; j < uBlur; j++) {
                sum += tex.sample(s, data.uv + float2(i, j) * (uRadius / uBlur)).rgb / pow(uBlur * 2.0, 2.0);
            }
        }
    } else {
        sum = tex.sample(s, data.uv).rgb;
    }
    return float4(sum, 1.0);
}
