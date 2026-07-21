fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &uTemperature [[buffer(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float4 pixel = tex.sample(s, data.uv);
    pixel.r = pixel.r + pixel.r * (1.0 - pixel.r) * uTemperature;
    pixel.b = pixel.b - pixel.b * (1.0 - pixel.b) * uTemperature;
    if (uTemperature > 0.0) pixel.g = pixel.g + pixel.g * (1.0 - pixel.g) * uTemperature * 0.25;
    float value = max(pixel.r, max(pixel.g, pixel.b));
    if (value > 1.0) pixel.rgb /= value;
    return pixel;
}
