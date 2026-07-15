fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float4 color = tex.sample(s, data.uv);
    float3 ncolor = float3(0.0, 0.0, 0.0);
    float value;
    if (color.r < 0.5) value = color.r;
    else value = 1.0 - color.r;
    float red = 4.0 * value * value * value;
    if (color.r < 0.5) ncolor.r = red;
    else ncolor.r = 1.0 - red;
    if (color.g < 0.5) value = color.g;
    else value = 1.0 - color.g;
    float green = 2.0 * value * value;
    if (color.g < 0.5) ncolor.g = green;
    else ncolor.g = 1.0 - green;
    ncolor.b = color.b * 0.5 + 0.25;
    return float4(ncolor.rgb, color.a);
}
