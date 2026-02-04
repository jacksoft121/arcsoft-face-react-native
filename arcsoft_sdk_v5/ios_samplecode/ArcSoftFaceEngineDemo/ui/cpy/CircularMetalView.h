#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CircularMetalView : MTKView

// 输入像素缓冲（NV12 / kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange or FullRange）
@property (nonatomic, assign) CVPixelBufferRef pixelBuffer;
// 视频原始尺寸（像素）
@property (nonatomic, assign) CGSize videoSize;

@end

NS_ASSUME_NONNULL_END

