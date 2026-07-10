//
//  RainbowFilter.metal
//  RootEncoder
//
//  Ported from Android rainbow_fragment.glsl
//  Concatenated after FilterVertex.metal at runtime.
//

inline float rainbowRgbToGray(float4 rgba) {
    const float3 W = float3(0.2125, 0.7154, 0.0721);
    return dot(rgba.xyz, W);
}

inline float3 rainbowHsv2rgb(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &uTime [[buffer(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    const float posterSteps = 4.0;
    const float lumaMult = 0.5;
    const float timeMult = 0.15;

    float4 color = tex.sample(s, data.uv);
    float luma = rainbowRgbToGray(color) * lumaMult;
    float lumaIndex = floor(luma * posterSteps);
    float lumaFloor = lumaIndex / posterSteps;
    float lumaRemainder = (luma - lumaFloor) * posterSteps;
    if (glslMod(lumaIndex, 2.0) == 0.0) lumaRemainder = 1.0 - lumaRemainder; //flip luma remainder for smooth color transitions
    float lumaCycle = glslMod(luma + uTime * timeMult, 1.0);
    float3 roygbiv = rainbowHsv2rgb(float3(lumaCycle, 1.0, lumaRemainder));
    return float4(roygbiv, 1.0);
}
