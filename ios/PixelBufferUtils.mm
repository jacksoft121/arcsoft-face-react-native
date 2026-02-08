#import "PixelBufferUtils.h"
#import <CoreVideo/CoreVideo.h>

@implementation PixelBufferUtils

+ (void)useOffscreenFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
                              block:(void(^)(ASVLOFFSCREEN *offscreen))block {
    if (!pixelBuffer || !block) return;

    // 1. 锁定内存，防止系统回收或移动
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

    const size_t width = CVPixelBufferGetWidth(pixelBuffer);
    const size_t height = CVPixelBufferGetHeight(pixelBuffer);
    const OSType fmt = CVPixelBufferGetPixelFormatType(pixelBuffer);

    ASVLOFFSCREEN offscreen = {0};
    void *bufferToFree = NULL;

    // ArcSoft SDK 通常期望 4 字节对齐的宽度/pitch。
    // 为了兼容性，我们将数据紧凑打包 (pitch = width 或 width*4)。

    if (fmt == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange ||
        fmt == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
        // NV12 格式处理

        offscreen.u32PixelArrayFormat = ASVL_PAF_NV12;
        offscreen.i32Width = (MInt32)width;
        offscreen.i32Height = (MInt32)height;

        // NV12 Y 平面每个像素 1 字节，所以 pitch = width
        int pitch = (int)width;
        offscreen.pi32Pitch[0] = pitch;
        offscreen.pi32Pitch[1] = pitch;

        // 获取原始数据的 stride (可能包含 padding)
        const size_t yStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
        const size_t uvStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);

        uint8_t *yBase = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        uint8_t *uvBase = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);

        size_t ySize = pitch * height;
        size_t uvSize = pitch * (height / 2);

        // 分配一块连续内存，同时存放 Y 和 UV 数据
        uint8_t *buf = (uint8_t *)malloc(ySize + uvSize);
        bufferToFree = buf;

        // 拷贝 Y 平面 (去除 padding)
        if ((int)yStride == pitch) {
            memcpy(buf, yBase, ySize);
        } else {
            for (int i = 0; i < height; i++) {
                memcpy(buf + i * pitch, yBase + i * yStride, width);
            }
        }

        // 拷贝 UV 平面 (去除 padding)
        // UV 平面紧跟在 Y 平面之后
        if ((int)uvStride == pitch) {
            memcpy(buf + ySize, uvBase, uvSize);
        } else {
            for (int i = 0; i < height / 2; i++) {
                memcpy(buf + ySize + i * pitch, uvBase + i * uvStride, width);
            }
        }

        offscreen.ppu8Plane[0] = buf;
        offscreen.ppu8Plane[1] = buf + ySize;

    } else if (fmt == kCVPixelFormatType_32BGRA) {
        // BGRA 格式处理

        offscreen.u32PixelArrayFormat = ASVL_PAF_RGB32_B8G8R8A8;
        offscreen.i32Width = (MInt32)width;
        offscreen.i32Height = (MInt32)height;

        // BGRA 每个像素 4 字节
        int pitch = (int)(width * 4);
        offscreen.pi32Pitch[0] = pitch;

        const size_t stride = CVPixelBufferGetBytesPerRow(pixelBuffer);
        uint8_t *base = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);

        size_t size = pitch * height;
        uint8_t *buf = (uint8_t *)malloc(size);
        bufferToFree = buf;

        // 拷贝数据 (去除 padding)
        if ((int)stride == pitch) {
            memcpy(buf, base, size);
        } else {
            for (int i = 0; i < height; i++) {
                memcpy(buf + i * pitch, base + i * stride, pitch);
            }
        }

        offscreen.ppu8Plane[0] = buf;
    }

    // 2. 执行回调
    if (bufferToFree) {
        block(&offscreen);
        // 3. 释放临时内存
        free(bufferToFree);
    } else {
        NSLog(@"[PixelBufferUtils] Unsupported pixel format: %d", (int)fmt);
    }

    // 4. 解锁内存
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
}

@end
