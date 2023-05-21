//
//  CubeShaders.metal
//  MetalDrawTextureDemo
//
//  Created by liqinghua on 12.5.23.
//

#include <metal_stdlib>
using namespace metal;

typedef struct {
    float4 position;
    float2 textureCoordinate;
    float4 color;
} VertextInput;

typedef struct {
    float4 position [[position]];
    float2 textureCoordinate;
    float4 color;
} RasterizerData;

typedef struct {
    float4x4 persMatrix;
    float4x4 mvMatrix;
} MvpMatrix;

vertex RasterizerData cubeVertexShader(uint vertexId [[vertex_id]],
                                       constant VertextInput *vertexs [[buffer(0)]],
                                       constant MvpMatrix *matrixs [[buffer(1)]]){
    RasterizerData out;
    
    //数据变换
    out.textureCoordinate = vertexs[vertexId].textureCoordinate;
    out.position = vertexs[vertexId].position;
    out.color = vertexs[vertexId].color;
    
    //此处进行位置矩阵变换
    out.position =  matrixs->persMatrix * matrixs->mvMatrix * out.position;
    
    return out;
}

fragment float4 cubeFragmentShader(RasterizerData input [[stage_in]],
                               texture2d<float> texture [[texture(0)]]){
    constexpr sampler textureSample (mag_filter::linear,min_filter::linear);
    float4 color = texture.sample(textureSample, input.textureCoordinate);
    return color;
    //return input.color;
}
