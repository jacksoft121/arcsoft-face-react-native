#include <metal_stdlib>
using namespace metal;

// vertex -> fragment structure
struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// vertex shader:
// buffer(1) = scale vector_float2 用于按比例 center-crop 视频采样
vertex VertexOut vertexShaderCircular(uint vid [[vertex_id]],
                                      constant vector_float2 &scale [[buffer(1)]]) {
    float2 positions[4] = { float2(-1.0, -1.0), float2(1.0, -1.0), float2(-1.0, 1.0), float2(1.0, 1.0) };
    float2 uvs[4]       = { float2(0.0, 1.0), float2(1.0, 1.0), float2(0.0, 0.0), float2(1.0, 0.0) };

    VertexOut out;
    out.position = float4(positions[vid], 0.0, 1.0);

    // apply scale for center-crop:
    // move uv to [-0.5,0.5], scale, move back
    float2 centered = uvs[vid] - 0.5;
    centered *= scale;
    out.texCoord = centered + 0.5;

    return out;
}

// fragment shader:
// texture(0) = Y plane (R8Unorm)
// texture(1) = UV plane (RG8Unorm) with interleaved Cb,Cr (NV12)
fragment float4 fragmentShaderCircular(VertexOut in [[stage_in]],
                                       texture2d<float, access::sample> yTexture [[texture(0)]],
                                       texture2d<float, access::sample> uvTexture [[texture(1)]],
                                       constant float * centerRadiusPtr [[buffer(0)]],
                                       sampler samp [[sampler(0)]]) {
    // sample Y and UV
    float y = yTexture.sample(samp, in.texCoord).r; // 0..1
    float2 uv = uvTexture.sample(samp, in.texCoord).rg; // uv.x = Cb, uv.y = Cr (0..1)

    // convert NV12 (assumes full range; for video range may need offsets & scaling)
    float cb = uv.x - 0.5;
    float cr = uv.y - 0.5;

    // Y range: if video-range (16..235) adjustment is needed. Here assume full range.
    float r = y + 1.402 * cr;
    float g = y - 0.344136 * cb - 0.714136 * cr;
    float b = y + 1.772 * cb;

    float4 color = float4(r, g, b, 1.0);

    // circular mask
    float cx = centerRadiusPtr[0];
    float cy = centerRadiusPtr[1];
    float radius = centerRadiusPtr[2];

    float2 diff = in.texCoord - float2(cx, cy);
    float dist = length(diff);

    if (dist > radius) {
        // outside circle: output transparent black (or you can output float4(0,0,0,1) for opaque black)
        return float4(0.0, 0.0, 0.0, 1.0);
    }

    return color;
}

