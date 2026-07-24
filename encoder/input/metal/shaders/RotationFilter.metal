fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &uRotation [[buffer(0)]],
                               constant float2 &uFlips [[buffer(1)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = data.uv;
    if (uFlips.x == 1.0) uv.x = 1.0 - uv.x;
    if (uFlips.y == 1.0) uv.y = 1.0 - uv.y;
    float2 centered = uv - 0.5;
    float c = cos(uRotation);
    float sn = sin(uRotation);
    float2 rotated = float2(centered.x * c - centered.y * sn, centered.x * sn + centered.y * c) + 0.5;
    if (rotated.x < 0.0 || rotated.x > 1.0 || rotated.y < 0.0 || rotated.y > 1.0) {
        return float4(0.0, 0.0, 0.0, 1.0);
    }
    return tex.sample(s, rotated);
}
