inline float3 distortedMod289(float3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

inline float2 distortedMod289(float2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

inline float3 distortedPermute(float3 x) {
    return distortedMod289(((x * 34.0) + 1.0) * x);
}

inline float distortedSnoise(float2 v) {
    const float4 C = float4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);

    float2 i = floor(v + dot(v, C.yy));
    float2 x0 = v - i + dot(i, C.xx);

    float2 i1;
    i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    i = distortedMod289(i);
    float3 p = distortedPermute(distortedPermute(i.y + float3(0.0, i1.y, 1.0))
    + i.x + float3(0.0, i1.x, 1.0));

    float3 m = max(0.5 - float3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;

    float3 x = 2.0 * fract(p * C.www) - 1.0;
    float3 h = abs(x) - 0.5;
    float3 ox = floor(x + 0.5);
    float3 a0 = x - ox;

    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);

    float3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

inline float distortedStaticV(float2 uv, float uTime) {
    float staticHeight = distortedSnoise(float2(9.0, uTime * 1.2 + 3.0)) * 0.3 + 5.0;
    float staticAmount = distortedSnoise(float2(1.0, uTime * 1.2 - 6.0)) * 0.1 + 0.3;
    float staticStrength = distortedSnoise(float2(-9.75, uTime * 0.6 - 3.0)) * 2.0 + 2.0;
    return (1.0 - step(distortedSnoise(float2(5.0 * pow(uTime, 2.0) + pow(uv.x * 7.0, 1.2), pow((glslMod(uTime, 100.0) + 100.0) * uv.y * 0.3 + 3.0, staticHeight))), staticAmount)) * staticStrength;
}

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &uTime [[buffer(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);

    float jerkOffset = (1.0 - step(distortedSnoise(float2(uTime * 1.3, 5.0)), 0.8)) * 0.05;
    float fuzzOffset = distortedSnoise(float2(uTime * 15.0, data.uv.y * 80.0)) * 0.003;
    float largeFuzzOffset = distortedSnoise(float2(uTime * 1.0, data.uv.y * 25.0)) * 0.004;
    float vertJerk = (1.0 - step(distortedSnoise(float2(uTime * 1.5, 5.0)), 0.6));
    float vertJerk2 = (1.0 - step(distortedSnoise(float2(uTime * 5.5, 5.0)), 0.2));
    float yOffset = vertJerk * vertJerk2 * 0.3;
    float y = glslMod(data.uv.y + yOffset, 1.0);
    float xOffset = fuzzOffset + largeFuzzOffset;

    float staticVal = 0.0;
    for (float i = -1.0; i <= 1.0; i += 1.0) {
        float maxDist = 5.0 / 200.0;
        float dist = i / 200.0;
        staticVal += distortedStaticV(float2(data.uv.x, data.uv.y + dist), uTime) * (maxDist - abs(dist)) * 1.5;
    }

    float red = tex.sample(s, float2(data.uv.x + xOffset - 0.01, y)).r + staticVal;
    float green = tex.sample(s, float2(data.uv.x + xOffset, y)).g + staticVal;
    float blue = tex.sample(s, float2(data.uv.x + xOffset + 0.01, y)).b + staticVal;

    float3 color = float3(red, green, blue);
    float scanline = sin(data.uv.y * 800.0) * 0.04;
    color -= scanline;

    return float4(color, 1.0) + jerkOffset * 0.0; //keep jerkOffset referenced like original
}
