//
//  ZebraFilter.metal
//  RootEncoder
//
//  Ported from Android zebra_fragment.glsl
//  Concatenated after FilterVertex.metal at runtime.
//

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &uTime [[buffer(0)]],
                               constant float &uLevels [[buffer(1)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float phase = uTime * 0.5;
    float4 color = tex.sample(s, data.uv);
    float4 tempColor = color;
    tempColor = glslMod(tempColor + phase, 1.0);
    tempColor = floor(tempColor * uLevels);
    tempColor = glslMod(tempColor, 2.0);
    return float4(tempColor.rgb, color.a);
}
