//
//  ChromaticAberrationFilter.metal
//  RootEncoder
//
//  Ported from Android chromatic_aberration_fragment.glsl
//  Concatenated after FilterVertex.metal at runtime.
//

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &uTime [[buffer(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float amount = (1.0 + sin(uTime * 6.0)) * 0.5;
    amount *= 1.0 + sin(uTime * 16.0) * 0.5;
    amount *= 1.0 + sin(uTime * 19.0) * 0.5;
    amount *= 1.0 + sin(uTime * 27.0) * 0.5;
    amount = pow(amount, 3.0);
    amount *= 0.05;

    float3 col;
    col.r = tex.sample(s, float2(data.uv.x + amount, data.uv.y)).r;
    col.g = tex.sample(s, data.uv).g;
    col.b = tex.sample(s, float2(data.uv.x - amount, data.uv.y)).b;

    col *= (1.0 - amount * 0.5);
    return float4(col, 1.0);
}
