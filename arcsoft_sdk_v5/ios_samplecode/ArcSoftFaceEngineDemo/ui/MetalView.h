//
//  MetalView.h
//

#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MetalView : MTKView
/// 用于渲染 CIImage 的上下文
@property (nonatomic, strong, readonly) CIContext *ciContext;

/// 当前视频帧的方向是否镜像（前置摄像头使用）
@property (nonatomic, assign, readonly) BOOL mirror;

/// 当前视频帧的分辨率
@property (nonatomic, assign, readonly) CGSize videoSize;

/// 当前帧的 PixelBuffer
@property (nonatomic, assign, readonly) CVPixelBufferRef currentPixelBuffer;

- (void)updatePixelBuffer:(CVPixelBufferRef)pixelBuffer mirror:(BOOL)mirror;

@end

NS_ASSUME_NONNULL_END

