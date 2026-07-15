fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float4 pixel = tex.sample(s, data.uv);
    float4 sepia = float4(clamp(pixel.x * 0.393 + pixel.y * 0.769 + pixel.z * 0.189, 0.0, 1.0),
        clamp(pixel.x * 0.349 + pixel.y * 0.686 + pixel.z * 0.168, 0.0, 1.0),
        clamp(pixel.x * 0.272 + pixel.y * 0.534 + pixel.z * 0.131, 0.0, 1.0),
        pixel.w);
    return sepia;
}
