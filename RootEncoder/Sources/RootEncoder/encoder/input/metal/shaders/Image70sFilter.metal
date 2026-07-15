fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float4 texColor = tex.sample(s, data.uv);
    float avg = (texColor.r + texColor.g + texColor.b) / 3.0; //grayscale
    texColor.r *= abs(cos(avg));
    texColor.g *= abs(sin(avg));
    texColor.b *= abs(atan(avg) * sin(avg));
    return texColor;
}
