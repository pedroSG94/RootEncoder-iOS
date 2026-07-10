//
//  AnalogTvFilter.metal
//  RootEncoder
//
//  Ported from Android analog_tv_fragment.glsl
//  Concatenated after FilterVertex.metal at runtime.
//

inline float analogTvRand(float2 co) {
    return fract(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
}

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &uTime [[buffer(0)]],
                               constant float2 &uResolution [[buffer(1)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = data.uv;
    uv -= 0.5;

    float3 col = tex.sample(s, uv + 0.5).rgb;

    float2 ruv = uv;
    ruv.x += 0.02;
    col.rgb += tex.sample(s, ruv + 0.5).rgb * 0.1;

    col += analogTvRand(fract(floor((ruv + uTime) * uResolution.y) * 0.7)) * 0.2;

    col *= clamp(fract(uv.y * 100.0 + uTime * 8.0), 0.8, 1.0);

    float bf = fract(uv.y * 3.0 + uTime * 26.0);
    float ff = min(bf, 1.0 - bf) + 0.35;
    col *= clamp(ff, 0.5, 0.75) + 0.75;

    col *= (sin(uTime * 120.0) * 0.5 + 0.5) * 0.1 + 0.9;

    col *= smoothstep(-0.51, -0.50, uv.x) * smoothstep(0.51, 0.50, uv.x);
    col *= smoothstep(-0.51, -0.50, uv.y) * smoothstep(0.51, 0.50, uv.y);

    return float4(col, 1.0);
}
