#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <ArcSoftFaceEngine/asvloffscreen.h>

NS_ASSUME_NONNULL_BEGIN

/// PixelBuffer 工具：CVPixelBuffer -> ASVLOFFSCREEN
/// 逐行对照官方 iOS Demo：util/Utility.m 的 getCameraDataFromSampleBuffer: / createOffscreen:
@interface PixelBufferUtils : NSObject

/// 从 CVPixelBuffer 生成 ASVLOFFSCREEN（仅支持 NV12 / BGRA）。
/// - Note: 返回的 offscreen 使用 malloc 分配内存，调用方用 free(offscreen.ppu8Plane[0])... 释放。
+ (ASVLOFFSCREEN)offscreenFromPixelBuffer:(CVPixelBufferRef)pixelBuffer;

/// 释放由 offscreenFromPixelBuffer: 分配的 plane 内存。
+ (void)freeOffscreen:(ASVLOFFSCREEN *)offscreen;

@end

NS_ASSUME_NONNULL_END
