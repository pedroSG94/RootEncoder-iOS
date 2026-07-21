fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &uCartoon [[buffer(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float3 t = tex.sample(s, data.uv).rgb;
    float3 t00 = tex.sample(s, data.uv + float2(-uCartoon, -uCartoon)).rgb;
    float3 t10 = tex.sample(s, data.uv + float2(uCartoon, -uCartoon)).rgb;
    float3 t01 = tex.sample(s, data.uv + float2(-uCartoon, uCartoon)).rgb;
    float3 t11 = tex.sample(s, data.uv + float2(uCartoon, uCartoon)).rgb;
    float3 tm = (t00 + t01 + t10 + t11) / 4.0;
    t = t - tm;
    t = t * t * t;
    float3 v = 10000.0 * t;
    float g = (tm.x - 0.3) * 5.0;
    float3 col0 = float3(0.0, 0.0, 0.0);
    float3 col1 = float3(0.2, 0.5, 1.0);
    float3 col2 = float3(1.0, 0.8, 0.7);
    float3 col3 = float3(1.0, 1.0, 1.0);
    float3 c;
    if (g > 2.0) c = mix(col2, col3, g - 2.0);
    else if (g > 1.0) c = mix(col1, col2, g - 1.0);
    else c = mix(col0, col1, g);
    c = clamp(c, 0.0, 1.0);
    v = clamp(v, 0.0, 1.0);
    v = c * (1.0 - v);
    v = clamp(v, 0.0, 1.0);
    if (all(v == col0)) v = col3;
    return float4(v, 1.0);
}
