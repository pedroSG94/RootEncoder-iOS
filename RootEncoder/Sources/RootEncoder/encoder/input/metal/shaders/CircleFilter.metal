//
//  CircleFilter.metal
//  RootEncoder
//
//  Ported from Android circle_fragment.glsl
//  Concatenated after FilterVertex.metal at runtime.
//

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float &uRadius [[buffer(0)]],
                               constant float2 &uCenter [[buffer(1)]],
                               constant float2 &uResolution [[buffer(2)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv;
    float2 center;
    if (uResolution.x < uResolution.y) {
        float scale = uResolution.y / uResolution.x;
        uv = float2(data.uv.x, data.uv.y * scale);
        center = float2(uCenter.x, uCenter.y * scale);
    } else {
        float scale = uResolution.x / uResolution.y;
        uv = float2(data.uv.x * scale, data.uv.y);
        center = float2(uCenter.x * scale, uCenter.y);
    }

    float dist = length(uv - center);
    if (dist < uRadius) return tex.sample(s, data.uv);
    return float4(0.0, 0.0, 0.0, 1.0);
}
