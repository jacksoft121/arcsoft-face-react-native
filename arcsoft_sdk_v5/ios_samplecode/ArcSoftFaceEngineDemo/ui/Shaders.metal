//
//  Shaders.metal
//  ArcSoftFaceEngineDemo
//
//  Created by arc-mac-m4 on 2025/9/8.
//  Copyright © 2025 ArcSoft. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


// 顶点输入数据
struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

// 顶点输出
struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// uniforms 参数：是否需要镜像
struct Uniforms {
    bool mirror;
    uint renderMode; // 0 = FullScreen, 1 = CircularCrop
};

// 顶点着色器
vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                              const device float4 *vertices [[buffer(0)]],
                              constant Uniforms &uniforms [[buffer(1)]]) {
    VertexOut out;
    out.position = float4(vertices[vertexID].xy, 0, 1);
    
    float2 texCoord = vertices[vertexID].zw;
    
    // 前置相机需要镜像
    if (uniforms.mirror) {
        texCoord.x = 1.0 - texCoord.x;
    }
    
    out.texCoord = texCoord;
    return out;
}

// 片元着色器
fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               texture2d<half> colorTexture [[texture(0)]]) {
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    return float4(colorTexture.sample(textureSampler, in.texCoord));
}
