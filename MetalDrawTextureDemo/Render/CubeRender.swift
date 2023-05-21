//
//  CubeRender.swift
//  MetalDrawTextureDemo
//
//  Created by liqinghua on 12.5.23.
//

import MetalKit
import GLKit

struct CubeVertexTexture{
    var vertex:vector_float4
    var texture:vector_float2
    var color:vector_float4
}

enum PositionChangeType{
    case x(Bool)
    case y(Bool)
    case z(Bool)
}

class CubeRender : NSObject{
    private var viewSize : CGSize = .zero
    private var imageName : String =  ""
    
    private var device : MTLDevice?
    private var commandQueue : MTLCommandQueue?
    private var pipelineState : MTLRenderPipelineState?
    private var viewPixelFormat : MTLPixelFormat!
    private var vertexBuffer : MTLBuffer?
    private var vertexIndexs : MTLBuffer?
    private var texture : MTLTexture?
    
    private var indexCount = 0
    
    init(mtkView:MTKView,imageName:String){
        super.init()
        self.viewSize = mtkView.bounds.size
        self.imageName = imageName
        
        self.viewPixelFormat = mtkView.colorPixelFormat
        self.device = mtkView.device
        self.customInit()
    }
    
    private func customInit(){
        setupPipelineState()
        setupVertexs()
        setupTextures()
    }
    
    private func setupPipelineState(){
        var library = device?.makeDefaultLibrary()
        if let url = Bundle.main.url(forResource: "CubeShaders", withExtension: "metal"){
            library = try? device?.makeLibrary(URL: url)
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library?.makeFunction(name: "cubeVertexShader")
        descriptor.fragmentFunction = library?.makeFunction(name: "cubeFragmentShader")
        descriptor.colorAttachments[0].pixelFormat = viewPixelFormat
        pipelineState = try? device?.makeRenderPipelineState(descriptor: descriptor)
        commandQueue = device?.makeCommandQueue()
    }
    
    private func setupVertexs(){
        let vertexs = [
            CubeVertexTexture(vertex: vector_float4(-0.5, 0.5, 0.0, 1.0),
                              texture: vector_float2(0.0, 1.0),
                              color: vector_float4(1.0,0.0,0.0,1.0)),//左上
            CubeVertexTexture(vertex: vector_float4(0.5, 0.5, 0.0, 1.0),
                              texture: vector_float2(1, 1),
                              color: vector_float4(0.0,1.0,0.0,1.0)),//右上
            CubeVertexTexture(vertex: vector_float4(0.5, -0.5, 0.0, 1.0),
                              texture: vector_float2(1.0, 0.0),
                              color: vector_float4(0.0,0.0,1.0,1.0)),//右下
            CubeVertexTexture(vertex: vector_float4(-0.5, -0.5, 0.0, 1.0),
                              texture: vector_float2(0.0, 0.0),
                              color: vector_float4(0.5,1.0,0.0,1.0)),//左下
            CubeVertexTexture(vertex: vector_float4(0.0, 0.0, 0.5, 1.0),
                              texture: vector_float2(0.5, 0.5),
                              color: vector_float4(0.0,5.0,0.5,1.0)),//中间顶点
        ]
        
        vertexBuffer = device?.makeBuffer(bytes: vertexs,
                                          length: MemoryLayout<CubeVertexTexture>.size * vertexs.count,
                                          options: .storageModeShared)
        
        let indexs : [Int32] = [
            0,1,2,
            0,2,3,
            0,3,4,
            0,4,1,
            1,4,2,
            2,4,3
        ]
        
        indexCount = indexs.count
        vertexIndexs = device?.makeBuffer(bytes: indexs,
                                          length: MemoryLayout<Int32>.size * indexs.count,
                                          options: .storageModeShared)
    }
    
    private func setupTextures(){
        let image = UIImage(named: imageName)
        guard let cgImage = image?.cgImage else{return}
        let width = cgImage.width
        let height = cgImage.height
        
        let spriteData : UnsafeMutablePointer = UnsafeMutablePointer<GLubyte>.allocate(capacity: MemoryLayout<GLubyte>.size * width * height * 4)
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        let context = CGContext(data: spriteData, width: width,
                                height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: cgImage.colorSpace!,
                                bitmapInfo: cgImage.bitmapInfo.rawValue)
        context?.translateBy(x: 0, y: CGFloat(height))
        context?.scaleBy(x: 1, y: -1)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsEndImageContext()
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .rgba8Unorm
        textureDescriptor.width = width
        textureDescriptor.height = height
        texture = device?.makeTexture(descriptor: textureDescriptor)
        texture?.replace(region: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                                           size: MTLSize(width: width, height: height, depth: 1)),
                         mipmapLevel: 0,
                         withBytes: spriteData,
                         bytesPerRow: 4 * width)
        free(spriteData)
    }
    
    private var x:Float = 0.0
    private var y:Float = 0.0
    private var z:Float = 0.0
    private var rotateOn : Bool = false
    private var xOn = false,yOn = false,zOn = false
    func positionChange(rotateOn:Bool,type:PositionChangeType){
        changeRorate(rotateOn: rotateOn)
        switch type {
        case .x(let isOn):
            xOn = isOn
        case .y(let isOn):
            yOn = isOn
        case .z(let isOn):
            zOn = isOn
        }
    }
    
    func changeRorate(rotateOn:Bool){
        self.rotateOn = rotateOn
    }
    
    private func changeMatrix() -> DqMatrix{
        let size = viewSize
        let perspectM = GLKMatrix4MakePerspective(Float.pi/2, Float(size.width/size.height), 0.1, 50.0)
        var modelViewM = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, -2)
        
        if rotateOn {
            if xOn {x += 1/180 * Float.pi}
            if yOn {y += 1/180 * Float.pi}
            if zOn {z += 1/180 * Float.pi}
        }
        
        modelViewM = GLKMatrix4RotateX(modelViewM, x)
        modelViewM = GLKMatrix4RotateY(modelViewM, y)
        modelViewM = GLKMatrix4RotateZ(modelViewM, z)
        
        let matrix = DqMatrix(pMatix: perspectM.toMatrix_float4x4(), mvMatrix: modelViewM.toMatrix_float4x4())
        return matrix
    }
}

struct DqMatrix {
    var pMatix : matrix_float4x4
    var mvMatrix :matrix_float4x4
}

extension GLKMatrix4{
    func toMatrix_float4x4() -> matrix_float4x4{
        let matrix = self
        return matrix_float4x4(
            simd_make_float4(matrix.m00, matrix.m01, matrix.m02, matrix.m03),
            simd_make_float4(matrix.m10, matrix.m11, matrix.m12, matrix.m13),
            simd_make_float4(matrix.m20, matrix.m21, matrix.m22, matrix.m23),
            simd_make_float4(matrix.m30, matrix.m31, matrix.m32, matrix.m33)
        )
    }
}

extension CubeRender : MTKViewDelegate{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewSize = size
    }
    
    func draw(in view: MTKView) {
        guard let passDescriptor = view.currentRenderPassDescriptor else{return}
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else{return}
        guard let pipelineState = self.pipelineState else{return}
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.5, 0.5, 1.0)
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor) else{return}
        commandEncoder.setRenderPipelineState(pipelineState)
        commandEncoder.setViewport(MTLViewport(originX: 0, originY: 0, width: viewSize.width, height: viewSize.height, znear: -1, zfar: 1))
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        var matrix = changeMatrix()
        commandEncoder.setVertexBytes(&matrix, length: MemoryLayout<DqMatrix>.size, index: 1)
        
        commandEncoder.setFragmentTexture(texture, index: 0)
        commandEncoder.setFrontFacing(.counterClockwise)
        commandEncoder.setCullMode(.back)
        
        commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexCount,
                                             indexType: .uint32, indexBuffer: vertexIndexs!,
                                             indexBufferOffset: 0)
        commandEncoder.endEncoding()
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
}
