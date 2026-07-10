//
//  SnowFilter.metal
//  RootEncoder
//
//  Ported from Android snow_fragment.glsl
//  Concatenated after FilterVertex.metal at runtime.
//

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &uTime [[buffer(0)]],
                               constant float &uLayers [[buffer(1)]],
                               constant float &uDepth [[buffer(2)]],
                               constant float &uWidth [[buffer(3)]],
                               constant float &uSpeed [[buffer(4)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    const float3x3 p = float3x3(
        float3(13.323122, 23.5112, 21.71123),
        float3(21.1212, 28.7312, 11.9312),
        float3(21.8112, 14.7212, 61.3934));

    float3 acc = float3(0.0);
    float dof = 5.0 * sin(uTime * 0.1);

    for (float i = 0.0; i < uLayers; i++) {
        float2 q = data.uv * (1.0 + i * uDepth);
        q += float2(q.y * (uWidth * glslMod(i * 7.238917, 1.0) - uWidth * 0.5), uSpeed * uTime / (1.0 + i * uDepth * 0.03));
        float3 n = float3(floor(q), 31.189 + i);
        float3 m = floor(n) * 0.00001 + fract(n);
        float3 mp = (31415.9 + m) / fract(p * m);
        float3 r = fract(mp);
        float2 sVal = abs(glslMod(q, 1.0) - 0.5 + 0.9 * r.xy - 0.45);
        sVal += 0.01 * abs(2.0 * fract(10.0 * q.yx) - 1.0);
        float d = 0.6 * max(sVal.x - sVal.y, sVal.x + sVal.y) + max(sVal.x, sVal.y) - 0.01;
        float edge = 0.005 + 0.05 * min(0.5 * abs(i - 5.0 - dof), 1.0);
        acc += float3(smoothstep(edge, -edge, d) * (r.x / (1.0 + 0.02 * i * uDepth)));
    }
    return tex.sample(s, data.uv) + float4(acc, 1.0);
}
