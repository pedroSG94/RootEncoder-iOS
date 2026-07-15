inline float beautyHardLight(float color) {
    if (color <= 0.5) {
        color = color * color * 2.0;
    } else {
        color = 1.0 - ((1.0 - color) * (1.0 - color) * 2.0);
    }
    return color;
}

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float2 &uResolution [[buffer(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    const float4 params = float4(0.748, 0.874, 0.241, 0.241);
    const float3 W = float3(0.299, 0.587, 0.114);
    const float3x3 saturateMatrix = float3x3(
        float3(1.1102, -0.0598, -0.061),
        float3(-0.0774, 1.0826, -0.1186),
        float3(-0.0228, -0.0228, 1.1772));

    float3 centralColor = tex.sample(s, data.uv).rgb;

    float2 blurCoordinates[24];
    blurCoordinates[0] = data.uv + uResolution * float2(0.0, -10.0);
    blurCoordinates[1] = data.uv + uResolution * float2(0.0, 10.0);
    blurCoordinates[2] = data.uv + uResolution * float2(-10.0, 0.0);
    blurCoordinates[3] = data.uv + uResolution * float2(10.0, 0.0);
    blurCoordinates[4] = data.uv + uResolution * float2(5.0, -8.0);
    blurCoordinates[5] = data.uv + uResolution * float2(5.0, 8.0);
    blurCoordinates[6] = data.uv + uResolution * float2(-5.0, 8.0);
    blurCoordinates[7] = data.uv + uResolution * float2(-5.0, -8.0);
    blurCoordinates[8] = data.uv + uResolution * float2(8.0, -5.0);
    blurCoordinates[9] = data.uv + uResolution * float2(8.0, 5.0);
    blurCoordinates[10] = data.uv + uResolution * float2(-8.0, 5.0);
    blurCoordinates[11] = data.uv + uResolution * float2(-8.0, -5.0);
    blurCoordinates[12] = data.uv + uResolution * float2(0.0, -6.0);
    blurCoordinates[13] = data.uv + uResolution * float2(0.0, 6.0);
    blurCoordinates[14] = data.uv + uResolution * float2(6.0, 0.0);
    blurCoordinates[15] = data.uv + uResolution * float2(-6.0, 0.0);
    blurCoordinates[16] = data.uv + uResolution * float2(-4.0, -4.0);
    blurCoordinates[17] = data.uv + uResolution * float2(-4.0, 4.0);
    blurCoordinates[18] = data.uv + uResolution * float2(4.0, -4.0);
    blurCoordinates[19] = data.uv + uResolution * float2(4.0, 4.0);
    blurCoordinates[20] = data.uv + uResolution * float2(-2.0, -2.0);
    blurCoordinates[21] = data.uv + uResolution * float2(-2.0, 2.0);
    blurCoordinates[22] = data.uv + uResolution * float2(2.0, -2.0);
    blurCoordinates[23] = data.uv + uResolution * float2(2.0, 2.0);

    float sampleColor = centralColor.g * 22.0;
    for (int i = 0; i < 12; i++) {
        sampleColor += tex.sample(s, blurCoordinates[i]).g;
    }
    for (int i = 12; i < 20; i++) {
        sampleColor += tex.sample(s, blurCoordinates[i]).g * 2.0;
    }
    for (int i = 20; i < 24; i++) {
        sampleColor += tex.sample(s, blurCoordinates[i]).g * 3.0;
    }
    sampleColor = sampleColor / 62.0;

    float highPass = centralColor.g - sampleColor + 0.5;
    for (int i = 0; i < 5; i++) {
        highPass = beautyHardLight(highPass);
    }
    float luminance = dot(centralColor, W);
    float alpha = pow(luminance, params.r);

    float3 smoothColor = centralColor + (centralColor - float3(highPass)) * alpha * 0.1;
    smoothColor.r = clamp(pow(smoothColor.r, params.g), 0.0, 1.0);
    smoothColor.g = clamp(pow(smoothColor.g, params.g), 0.0, 1.0);
    smoothColor.b = clamp(pow(smoothColor.b, params.g), 0.0, 1.0);

    float3 screen = float3(1.0) - (float3(1.0) - smoothColor) * (float3(1.0) - centralColor);
    float3 lighten = max(smoothColor, centralColor);
    float3 softLight = 2.0 * centralColor * smoothColor + centralColor * centralColor
                       - 2.0 * centralColor * centralColor * smoothColor;

    float4 color = float4(mix(centralColor, screen, alpha), 1.0);
    color.rgb = mix(color.rgb, lighten, alpha);
    color.rgb = mix(color.rgb, softLight, params.b);

    float3 satColor = color.rgb * saturateMatrix;
    color.rgb = mix(color.rgb, satColor, params.a);

    color.rgb = color.rgb + float3(-0.096);
    return color;
}
