fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &uGamma [[buffer(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float4 pixel = tex.sample(s, data.uv);
    return float4(pow(pixel.rgb, float3(uGamma)), pixel.a);
}
