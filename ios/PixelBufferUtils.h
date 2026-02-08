#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <ArcSoftFaceEngine/asvloffscreen.h>

NS_ASSUME_NONNULL_BEGIN

@interface PixelBufferUtils : NSObject

/**
 * 将 CVPixelBuffer 转换为 ArcSoft 所需的 ASVLOFFSCREEN 格式，并在 block 中回调使用。
 *
 * 逻辑说明：
 * 1. 自动锁定 CVPixelBuffer (LockBaseAddress)。
 * 2. 处理图像 stride (padding)：
 *    ArcSoft SDK 部分算法对非紧凑排列的内存支持有限，因此这里会将带有 padding 的
 *    CVPixelBuffer 数据逐行拷贝到一块新的连续内存中 (malloc)，确保 pitch == width。
 * 3. 执行 block 回调，传入构造好的 ASVLOFFSCREEN 指针。
 * 4. block 执行完毕后，自动释放 malloc 的内存并解锁 CVPixelBuffer。
 *
 * @param pixelBuffer 原始视频帧数据
 * @param block 使用 offscreen 的回调闭包
 */
+ (void)useOffscreenFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
                              block:(void(^)(ASVLOFFSCREEN *offscreen))block;

@end

NS_ASSUME_NONNULL_END
