//
//  SaturationFilter.metal
//  RootEncoder
//
//  Ported from Android saturation_fragment.glsl
//  Concatenated after FilterVertex.metal at runtime.
//

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &uShift [[buffer(0)]],
                               constant float3 &uWeights [[buffer(1)]],
                               constant float3 &uExponents [[buffer(2)]],
                               constant float &uSaturation [[buffer(3)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float4 oldcolor = tex.sample(s, data.uv);
    float kv = dot(oldcolor.rgb, uWeights) + uShift;
    float3 new_color = uSaturation * oldcolor.rgb + (1.0 - uSaturation) * kv;
    float4 result = float4(new_color, oldcolor.a);

    float4 color = tex.sample(s, data.uv);
    float de = dot(color.rgb, uWeights);
    float inv_de = 1.0 / de;
    float3 verynew_color = de * pow(color.rgb * inv_de, uExponents);
    float max_color = max(max(max(verynew_color.r, verynew_color.g), verynew_color.b), 1.0);
    return result + float4(verynew_color / max_color, color.a);
}
