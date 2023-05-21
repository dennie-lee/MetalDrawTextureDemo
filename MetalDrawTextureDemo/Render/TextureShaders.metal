//
//  Shaders.metal
//  MetalDrawTextureDemo
//
//  Created by liqinghua on 11.5.23.
//

#include <metal_stdlib>
using namespace metal;

typedef struct {
    float2 position;
    float2 textureCoordinate;
    float4 color;
} VertexInput;

typedef struct {
    float4 position [[position]];
    float2 textureCoordinate;
    float4 color;
} RasterizerData;

vertex RasterizerData vertexShader(uint vertexId [[vertex_id]],
                                   constant VertexInput *vertexs [[buffer(0)]]){
    RasterizerData out;
    out.position = vector_float4(0.0,0.0,0.0,1.0);
    out.position.xy = vertexs[vertexId].position;
    out.textureCoordinate = vertexs[vertexId].textureCoordinate;
    out.color = vertexs[vertexId].color;
    return out;
};

fragment float4 fragmentShader(RasterizerData input [[stage_in]],
                               texture2d<float> colorTexture [[texture(0)]]){
    constexpr sampler textureSampler (mag_filter::linear,min_filter::linear);
    //float4 color = colorTexture.sample(textureSampler, input.textureCoordinate) * input.color;
    float4 color = colorTexture.sample(textureSampler, input.textureCoordinate);
    return color;
};
