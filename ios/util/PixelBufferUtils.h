#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

@interface PixelBufferUtils : NSObject

/// 将 CVPixelBuffer(NV12) 拷贝成连续内存（Y + UV）
+ (nullable NSData *)copyNV12Bytes:(CVPixelBufferRef)pixelBuffer
                             width:(int *)outW
                            height:(int *)outH;

@end

NS_ASSUME_NONNULL_END
