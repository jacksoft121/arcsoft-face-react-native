#import "CircularMetalView.h"
#import <MetalKit/MetalKit.h>
#import <simd/simd.h>

@interface CircularMetalView () <MTKViewDelegate>
{
    id<MTLRenderPipelineState> _pipelineState;
    id<MTLCommandQueue> _commandQueue;
    CVMetalTextureCacheRef _textureCache;

    id<MTLBuffer> _scaleBuffer;
    id<MTLBuffer> _centerRadiusBuffer;
}
@end

@implementation CircularMetalView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) [self commonInit];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame device:(id<MTLDevice>)device {
    self = [super initWithFrame:frame device:device];
    if (self) [self commonInit];
    return self;
}

- (void)commonInit {
    self.device = MTLCreateSystemDefaultDevice();
    self.delegate = self;
    self.framebufferOnly = NO;
    self.enableSetNeedsDisplay = YES;
    self.paused = YES;
    self.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundColor = UIColor.whiteColor;

    _commandQueue = [self.device newCommandQueue];
    CVMetalTextureCacheCreate(NULL, NULL, self.device, NULL, &_textureCache);

    [self setupPipeline];
}

- (void)setupPipeline {
    NSError *error = nil;
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    if (!library) {
        NSLog(@"❌ Metal library not found, please ensure .metal file is compiled.");
        return;
    }

    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"vertexShaderCircular"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fragmentShaderCircular"];

    MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
    desc.vertexFunction = vertexFunc;
    desc.fragmentFunction = fragmentFunc;
    desc.colorAttachments[0].pixelFormat = self.colorPixelFormat;

    _pipelineState = [self.device newRenderPipelineStateWithDescriptor:desc error:&error];
    if (error) NSLog(@"❌ Pipeline error: %@", error);
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)setPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (_pixelBuffer == pixelBuffer) return;
    if (_pixelBuffer) CVPixelBufferRelease(_pixelBuffer);
    if (pixelBuffer) CVPixelBufferRetain(pixelBuffer);
    _pixelBuffer = pixelBuffer;
    [self draw];
}

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView *)view {
    if (!_pixelBuffer || !_pipelineState) return;

    // --- 1) 同步 drawableSize ---
    CGFloat screenScale = [UIScreen mainScreen].scale;
    CGSize viewBounds = self.bounds.size; // points
    CGSize desiredDrawableSize = CGSizeMake(viewBounds.width * screenScale,
                                            viewBounds.height * screenScale);
    if (!CGSizeEqualToSize(view.drawableSize, desiredDrawableSize)) {
        view.drawableSize = desiredDrawableSize;
    }

    // Debug 打印
    NSLog(@"[Draw] bounds(pt)=%.1f×%.1f drawable(px)=%.1f×%.1f scale=%.1f",
          viewBounds.width, viewBounds.height,
          view.drawableSize.width, view.drawableSize.height,
          screenScale);

    // --- 2) 创建 NV12 纹理 ---
    size_t yWidth  = CVPixelBufferGetWidthOfPlane(_pixelBuffer, 0);
    size_t yHeight = CVPixelBufferGetHeightOfPlane(_pixelBuffer, 0);
    size_t uvWidth = CVPixelBufferGetWidthOfPlane(_pixelBuffer, 1);
    size_t uvHeight = CVPixelBufferGetHeightOfPlane(_pixelBuffer, 1);

    CVMetalTextureRef yTexRef = NULL;
    CVMetalTextureRef uvTexRef = NULL;
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                              _textureCache, _pixelBuffer, NULL,
                                              MTLPixelFormatR8Unorm,
                                              yWidth, yHeight, 0, &yTexRef);
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                              _textureCache, _pixelBuffer, NULL,
                                              MTLPixelFormatRG8Unorm,
                                              uvWidth, uvHeight, 1, &uvTexRef);

    id<MTLTexture> yTexture = yTexRef ? CVMetalTextureGetTexture(yTexRef) : nil;
    id<MTLTexture> uvTexture = uvTexRef ? CVMetalTextureGetTexture(uvTexRef) : nil;
    if (!yTexture || !uvTexture) {
        if (yTexRef) CFRelease(yTexRef);
        if (uvTexRef) CFRelease(uvTexRef);
        return;
    }

    // --- 3) 渲染准备 ---
    MTLRenderPassDescriptor *pass = view.currentRenderPassDescriptor;
    id<CAMetalDrawable> drawable = view.currentDrawable;
    if (!pass || !drawable) {
        CFRelease(yTexRef);
        CFRelease(uvTexRef);
        return;
    }

    id<MTLCommandBuffer> cmd = [_commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [cmd renderCommandEncoderWithDescriptor:pass];
    [encoder setRenderPipelineState:_pipelineState];

    // --- 4) 纹理与采样器 ---
    [encoder setFragmentTexture:yTexture atIndex:0];
    [encoder setFragmentTexture:uvTexture atIndex:1];

    MTLSamplerDescriptor *samp = [[MTLSamplerDescriptor alloc] init];
    samp.minFilter = MTLSamplerMinMagFilterLinear;
    samp.magFilter = MTLSamplerMinMagFilterLinear;
    samp.sAddressMode = MTLSamplerAddressModeClampToEdge;
    samp.tAddressMode = MTLSamplerAddressModeClampToEdge;
    id<MTLSamplerState> sampler = [self.device newSamplerStateWithDescriptor:samp];
    [encoder setFragmentSamplerState:sampler atIndex:0];

    // --- 5) viewport：取 drawable 中心正方形区域 ---
    CGSize ds = view.drawableSize; // px
    double dw = ds.width;
    double dh = ds.height;
    double side = MIN(dw, dh);
    double originX = (dw - side) * 0.5;
    double originY = (dh - side) * 0.5;
    MTLViewport vp = {originX, originY, side, side, 0.0, 1.0};
    [encoder setViewport:vp];

    // --- 6) 计算纹理等比缩放（防止拉伸） ---
    float videoAspect = (float)yWidth / (float)yHeight;
    vector_float2 scale = {1.0f, 1.0f};
    if (videoAspect > 1.0f) scale.x = 1.0f / videoAspect;
    else                    scale.y = videoAspect;

    _scaleBuffer = [self.device newBufferWithBytes:&scale
                                            length:sizeof(scale)
                                           options:MTLResourceStorageModeShared];
    [encoder setVertexBuffer:_scaleBuffer offset:0 atIndex:1];

    // --- 7) 圆半径计算：直径 = 手机屏宽的一半 ---
    CGFloat screenWidthPt = UIScreen.mainScreen.bounds.size.width;
    CGFloat screenWidthPx = screenWidthPt * screenScale;
    CGFloat circleDiameterPx = screenWidthPx * 0.6;
    CGFloat circleRadiusPx = circleDiameterPx / 2.0;

    // 保证不超过 viewport 区域
    float maxRadiusPx = side * 0.5f;
    float finalRadiusPx = (float)MIN(circleRadiusPx, maxRadiusPx);

    // 转为 [0,1] 范围（相对 viewport）
    float radiusNorm = finalRadiusPx / side;
    float centerRadius[3] = {0.5f, 0.5f, radiusNorm};
    _centerRadiusBuffer = [self.device newBufferWithBytes:centerRadius
                                                   length:sizeof(centerRadius)
                                                  options:MTLResourceStorageModeShared];
    [encoder setFragmentBuffer:_centerRadiusBuffer offset:0 atIndex:0];

    NSLog(@"[Circle] screen=%.1fpx circle=%.1fpx radiusNorm=%.4f viewportSide=%.1f",
          screenWidthPx, circleDiameterPx, radiusNorm, side);

    // --- 8) draw ---
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    [cmd presentDrawable:drawable];
    [cmd commit];

    CFRelease(yTexRef);
    CFRelease(uvTexRef);
}



- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    // not used
}

@end

