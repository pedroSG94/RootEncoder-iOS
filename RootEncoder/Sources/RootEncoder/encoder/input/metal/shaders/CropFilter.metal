//
//  CropFilter.metal
//  RootEncoder
//
//  Ported from Android CropFilterRender (vertex matrix crop implemented as uv remap).
//  uArea is (offsetX, offsetY, width, height) normalized 0.0 to 1.0 from top left corner.
//  Concatenated after FilterVertex.metal at runtime.
//

fragment float4 fragmentFilter(FilterData data [[stage_in]],
                               texture2d<float> tex [[texture(0)]],
                               constant float4 &uArea [[buffer(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    //uv origin is bottom left, crop area origin is top left
    float x = uArea.x + data.uv.x * uArea.z;
    float y = 1.0 - (uArea.y + (1.0 - data.uv.y) * uArea.w);
    return tex.sample(s, float2(x, y));
}
