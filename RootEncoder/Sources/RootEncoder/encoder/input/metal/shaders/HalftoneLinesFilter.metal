//
//  HalftoneLinesFilter.metal
//  RootEncoder
//
//  Ported from Android halftone_lines_fragment.glsl
//  Concatenated after FilterVertex.metal at runtime.
//

inline float halftoneRgbToGray(float4 rgba) {
    const float3 W = float3(0.2125, 0.7154, 0.0721);
    return dot(rgba.xyz, W);
}

inline float halftoneAverageGray(texture2d<float> tex, float2 uv, float stepX, float stepY) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float4 result = float4(0.0);
    result += tex.sample(s, uv + float2(-stepX, stepY));
    result += tex.sample(s, uv + float2(0.0, stepY));
    result += tex.sample(s, uv + float2(stepX, stepY));
    result += tex.sample(s, uv + float2(-stepX, 0.0));
    result += tex.sample(s, uv);
    result += tex.sample(s, uv + float2(stepX, 0.0));
    result += tex.sample(s, uv + float2(-stepX, -stepY));
    result += tex.sample(s, uv + float2(0.0, -stepY));
    result += tex.sample(s, uv + float2(stepX, -stepY));
    return halftoneRgbToGray(result) / 9.0;
}

inline float2 halftoneRotateCoord(float2 uv, float rads) {
    uv = uv * float2x2(float2(cos(rads), sin(rads)), float2(-sin(rads), cos(rads)));
    return uv;
}

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float2 &uResolution [[buffer(0)]],
                               constant float &uMode [[buffer(1)]],
                               constant float &uRows [[buffer(2)]],
                               constant float &uRotation [[buffer(3)]],
                               constant float &uAntialias [[buffer(4)]],
                               constant float2 &uSampleDist [[buffer(5)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    // halftone line coords
    float2 uvRow = fract(halftoneRotateCoord(data.uv, uRotation) * uRows);
    float2 uvFloorY = float2(data.uv.x, floor(data.uv.y * uRows) / uRows) + float2(0.0, (1.0 / uRows) * 0.5);
    // get averaged gray for row
    float averagedBW = halftoneAverageGray(tex, uvFloorY, uSampleDist.x / uResolution.x, uSampleDist.y / uResolution.y);
    // use averaged gray to set line thickness
    float3 finalColor = float3(1.0);
    if (uMode == 1.0) {
        if (uvRow.y > averagedBW) finalColor = float3(0.0);
    } else if (uMode == 2.0) {
        if (abs(uvRow.y + 0.5 - averagedBW * 2.0) < 0.2) finalColor = float3(0.0);
    } else if (uMode == 3.0) {
        float distFromRowCenter = 1.0 - abs(uvRow.y - 0.5) * 2.0;
        finalColor = float3(1.0 - smoothstep(averagedBW - uAntialias, averagedBW + uAntialias, distFromRowCenter));
    } else if (uMode == 4.0) {
        float2 uvRow2 = fract(halftoneRotateCoord(data.uv, -uRotation) * uRows);
        float distFromRowCenter1 = 1.0 - abs(uvRow.y - 0.5) * 2.0;
        float distFromRowCenter2 = 1.0 - abs(uvRow2.y - 0.5) * 2.0;
        float distFromRowCenter = min(distFromRowCenter1, distFromRowCenter2);
        finalColor = float3(1.0 - smoothstep(averagedBW - uAntialias, averagedBW + uAntialias, distFromRowCenter));
    } else if (uMode == 5.0) {
        float2 uvRow2 = fract(halftoneRotateCoord(data.uv, -uRotation) * uRows);
        float distFromRowCenter1 = 1.0 - abs(uvRow.y - 0.5) * 2.0;
        float distFromRowCenter2 = 1.0 - abs(uvRow2.y - 0.5) * 2.0;
        float distFromRowCenter = mix(distFromRowCenter1, distFromRowCenter2, 0.5);
        finalColor = float3(1.0 - smoothstep(averagedBW - uAntialias, averagedBW + uAntialias, distFromRowCenter));
    } else if (uMode == 6.0) {
        float rot = floor(averagedBW * 6.28) / 6.28;
        rot = rot * 4.0;
        float2 uvRowLocal = fract(halftoneRotateCoord(data.uv, rot) * uRows);
        float distFromRowCenter = 1.0 - abs(uvRowLocal.y - 0.5) * 2.0;
        finalColor = float3(1.0 - smoothstep(averagedBW - uAntialias, averagedBW + uAntialias, distFromRowCenter));
    } else if (uMode == 7.0) {
        float4 originalColor = tex.sample(s, uvFloorY);
        float distFromRowCenter = 1.0 - abs(uvRow.y - 0.5) * 2.0;
        float mixValue = 1.0 - smoothstep(averagedBW - uAntialias, averagedBW + uAntialias, distFromRowCenter);
        finalColor = mix(originalColor.rgb, float3(1.0), mixValue);
    }
    return float4(finalColor, 1.0);
}
