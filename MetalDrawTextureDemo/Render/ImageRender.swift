//
//  ImageRender.swift
//  MetalDrawTextureDemo
//
//  Created by liqinghua on 12.5.23.
//

import MetalKit

struct VertexTexture{
    var vertex : vector_float2
    var texture : vector_float2
    var color : vector_float4
}

//Metal绘制图片
class ImageRender : NSObject{
    private var device : MTLDevice?
    private var viewColorPixelformat : MTLPixelFormat!
    private var pipelineState : MTLRenderPipelineState?
    private var commandQueue : MTLCommandQueue?
    private var vertexBuffer : MTLBuffer?
    private var texture : MTLTexture?
    private var vertexIndexs : MTLBuffer?
    
    private var viewFrame : CGRect = .zero
    private var viewSize = CGSize.zero
    private var imageScale:(CGFloat,CGFloat) = (1,1)
    private var scaleToShow = true
    private var imageName : String = ""
    
    
    init(mtkView:MTKView,
         scaleToShow:Bool = true,
         imageName:String){
        super.init()
        self.viewFrame = mtkView.frame
        self.viewSize = mtkView.drawableSize
        self.scaleToShow = scaleToShow
        self.imageName = imageName
        
        self.device = mtkView.device
        self.viewColorPixelformat = mtkView.colorPixelFormat
        self.customInit()
    }
    
    private func customInit(){
        setupPilineState()
        setupVertexs()
        setupImageTexture()
    }
    
    
    private func setupPilineState(){
        //获取默认库并为每个函数获取一个MTLFunction对象和创建一个 MTLRenderPipelineState 对象。
        //渲染管道有更多阶段需要配置，可以使用 MTLRenderPipelineDescriptor 来配置管道
        var library = device?.makeDefaultLibrary()
        if let url = Bundle.main.url(forResource: "TextureShaders", withExtension: "metal"){
            library = try? device?.makeLibrary(URL: url)
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library?.makeFunction(name: "vertexShader")
        descriptor.fragmentFunction = library?.makeFunction(name: "fragmentShader")
        descriptor.colorAttachments[0].pixelFormat = viewColorPixelformat
        pipelineState = try? device?.makeRenderPipelineState(descriptor: descriptor)
        commandQueue = device?.makeCommandQueue()
    }
    
    //初始化顶点数据
    private func setupVertexs(){
        if scaleToShow{
            scaleShowImage()
            return
        }
        fixedShow()
    }
    
    //固定大小的方式渲染图片
    func fixedShow(){
        let vertexs : [VertexTexture] = [
            VertexTexture(vertex: vector_float2(0.8, -0.7),
                          texture: vector_float2(1.0, 0.0),
                          color: vector_float4(1.0,0.0,0.0,1.0)),
            VertexTexture(vertex: vector_float2(-0.8, -0.7),
                          texture: vector_float2(0.0, 0.0),
                          color: vector_float4(1.0,0.0,0.0,1.0)),
            VertexTexture(vertex: vector_float2(-0.8, 0.7),
                          texture: vector_float2(0.0, 1.0),
                          color: vector_float4(1.0,0.0,0.0,1.0)),
            VertexTexture(vertex: vector_float2(0.8, 0.7),
                          texture: vector_float2(1.0, 1.0),
                          color: vector_float4(1.0,0.0,0.0,1.0))
        ]
        
        vertexBuffer = device?.makeBuffer(bytes: vertexs,
                                                  length: MemoryLayout<VertexTexture>.size * vertexs.count,
                                                  options: .storageModeShared)
        
        let indexs : [Int32] = [0,1,2,0,2,3]
        vertexIndexs = device?.makeBuffer(bytes: indexs,
                                                  length: MemoryLayout<Int32>.size * 6,
                                                  options: .storageModeShared)
    }
    
    //根据图片缩放比例渲染图片，不会拉伸图片
    func scaleShowImage(){
        let image = UIImage(named: imageName)
        var vertexs:[Float] = [
            1, -1,  1,1,  1.0,0.0,0.0,1.0,
            -1,-1,  0,1,  1.0,0.0,0.0,1.0,
            -1, 1,  0,0,  1.0,0.0,0.0,1.0,
            1,  1,  1,0,  1.0,0.0,0.0,1.0,
        ]
        
        if let cgImage = image?.cgImage {
            let width = cgImage.width
            let height = cgImage.height
            let scaleF = CGFloat(viewFrame.height)/CGFloat(viewFrame.width)
            let scaleI = CGFloat(height)/CGFloat(width)
            imageScale = scaleF>scaleI ? (1,scaleI/scaleF) : (scaleI/scaleF,1)
        }
        
        for (i,v) in vertexs.enumerated(){
            if i % 4 == 0 {
                vertexs[i] = v * Float(imageScale.0)
            }
            if i % 4 == 1{
                vertexs[i] = v * Float(imageScale.1)
            }
        }
        //顶点数据
        vertexBuffer = device?.makeBuffer(bytes: vertexs, length: MemoryLayout<Float>.size * vertexs.count, options: MTLResourceOptions.storageModeShared)
        
        //顶点索引
        let indexs : [Int32] = [0,1,2,0,2,3]
        vertexIndexs = device?.makeBuffer(bytes: indexs,
                                                  length: MemoryLayout<Int32>.size * 6,
                                                  options: .storageModeShared)
    }
    
    //获取图片纹理
    private func setupImageTexture(){
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
        //使用该方式图片会上下颠倒，改用下面的方式
        //context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPushContext(context!);
        image?.draw(in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        
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
}

extension ImageRender : MTKViewDelegate{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewSize = size
    }
    
    func draw(in view: MTKView) {
        guard let vertexIndexs = self.vertexIndexs else{return}
        guard let pipelineState = self.pipelineState else{return}
        let commandBuffer = commandQueue?.makeCommandBuffer()
        guard let passDescriptor = view.currentRenderPassDescriptor else{return}
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.5, 0.5, 1.0)
        guard let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: passDescriptor) else{return}
        //为要使用的管道设置渲染管道状态
        commandEncoder.setRenderPipelineState(pipelineState)
        //设置视口，以便 Metal 知道要绘制到渲染目标的哪一部分
        commandEncoder.setViewport(MTLViewport(originX: 0, originY: 0,
                                               width: viewSize.width, height: viewSize.height,
                                               znear: -1.0, zfar: 1.0))
        //通常使用缓冲区(MTLBuffer)将数据传递给着色器。
        //然而，当只需要将少量数据传递给顶点函数时，就像这里的情况一样，将数据直接复制到命令缓冲区中
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.setFragmentTexture(texture, index: 0)
        commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: 6,
                                             indexType: .uint32, indexBuffer: vertexIndexs,
                                             indexBufferOffset: 0)
        commandEncoder.endEncoding()
        commandBuffer?.present(view.currentDrawable!)
        commandBuffer?.commit()
    }
}
