//
//  PolygonizationFilter.metal
//  RootEncoder
//
//  Ported from Android polygonization_fragment.glsl
//  Concatenated after FilterVertex.metal at runtime.
//

inline float2 polygonHash2(float2 p) {
    return fract(sin(float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)))) * 43758.5453);
}

inline float2 polygonVoronoi(float2 x) {
    float2 n = floor(x);
    float2 f = fract(x);
    float2 mg, mr;
    float md = 8.0;
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            float2 g = float2(float(i), float(j));
            float2 o = polygonHash2(n + g);
            float2 r = g + o - f;
            float d = dot(r, r);
            if (d < md) {
                md = d;
                mr = r;
                mg = g;
            }
        }
    }
    return mr;
}

inline float3 polygonVoronoiColor(texture2d<float> tex, float steps, float2 p, float2 uv, float2 uResolution) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 c = polygonVoronoi(steps * p);
    float2 uv1 = uv;
    uv1.x += c.x / steps;
    uv1.y += c.y / steps * uResolution.x / uResolution.y;
    return tex.sample(s, float2(uv1.x, uv1.y)).xyz;
}

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float2 &uResolution [[buffer(0)]]) {
    float2 p = (data.uv * uResolution).xy / uResolution.xx;
    float2 uv = (data.uv * uResolution).xy / uResolution.xy;
    float3 color = float3(0.0, 0.0, 0.0);
    for (float i = 0.0; i < 4.0; i += 1.0) {
        float steps = 30.0 * pow(2.0, i);
        color += polygonVoronoiColor(tex, steps, p, uv, uResolution);
    }
    return float4(color * 0.25, 1.0);
}
