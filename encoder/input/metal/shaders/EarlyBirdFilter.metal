inline float3x3 earlyBirdSaturationMatrix(float saturation) {
    float3 luminance = float3(0.3086, 0.6094, 0.0820);
    float oneMinusSat = 1.0 - saturation;
    float3 red = float3(luminance.x * oneMinusSat);
    red.r += saturation;

    float3 green = float3(luminance.y * oneMinusSat);
    green.g += saturation;

    float3 blue = float3(luminance.z * oneMinusSat);
    blue.b += saturation;

    return float3x3(red, green, blue);
}

inline void earlyBirdLevels(thread float3 &col, float3 inleft, float3 inright, float3 outleft, float3 outright) {
    col = clamp(col, inleft, inright);
    col = (col - inleft) / (inright - inleft);
    col = outleft + col * (outright - outleft);
}

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float2 &uResolution [[buffer(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float3 col = tex.sample(s, data.uv).rgb;
    float2 fragCoord = data.uv * uResolution;
    float2 coord = (fragCoord + fragCoord - uResolution) / uResolution.y;
    float3 gradient = float3(pow(1.0 - length(coord * 0.4), 0.6) * 1.2);
    float3 grey = float3(184.0 / 255.0);
    float3 tint = float3(252.0, 243.0, 213.0) / 255.0;
    col = earlyBirdSaturationMatrix(0.68) * col;
    earlyBirdLevels(col, float3(0.0), float3(1.0), float3(27.0, 0.0, 0.0) / 255.0, float3(255.0) / 255.0);
    col = pow(col, float3(1.19));
    //brightnessAdjust
    col += 0.13;
    //contrastAdjust
    float t = 0.5 - 1.05 * 0.5;
    col = col * 1.05 + t;

    col = earlyBirdSaturationMatrix(0.85) * col;
    earlyBirdLevels(col, float3(0.0), float3(235.0 / 255.0), float3(0.0, 0.0, 0.0) / 255.0, float3(255.0) / 255.0);
    col = mix(tint * col, col, gradient);
    col = 1.0 - (1.0 - col) / grey; //colorBurn
    return float4(col, 1.0);
}
