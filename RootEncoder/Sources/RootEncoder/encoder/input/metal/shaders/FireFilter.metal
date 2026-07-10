//
//  FireFilter.metal
//  RootEncoder
//
//  Ported from Android fire_fragment.glsl
//  Concatenated after FilterVertex.metal at runtime.
//

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float2 &uResolution [[buffer(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    const float2 texel_size = float2(6.0, 6.0);
    float2 fragCoord = data.uv * uResolution;
    fragCoord = floor(fragCoord / texel_size); //Pixelify
    fragCoord /= uResolution / texel_size; //Correct scale
    float reaction_coordinate = tex.sample(s, fragCoord).r; //Use red channel
    float mixval = ((reaction_coordinate - 0.55) * 10.0 + 0.5) * 2.0;
    float4 color = float4(mix(float3(1.0, 0.58, 0.0), float3(1.0, 0.7, 0.4), mixval), reaction_coordinate);
    color.rgb = float3(1.0, 0.2, 0.0); //Red
    if (color.a > 0.65) color.rgb = float3(1.0, 1.0, 1.0); //White
    else if (color.a > 0.37) color.rgb = float3(1.4, 0.8, 0.0); //Yellow
    color.a = float(color.a > 0.1);
    return color;
}
