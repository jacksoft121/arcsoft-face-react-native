#import "PixelBufferUtils.h"
#import <CoreVideo/CoreVideo.h>

@implementation PixelBufferUtils

+ (ASVLOFFSCREEN)offscreenFromPixelBuffer:(CVPixelBufferRef)pixelBuffer {
  // 逐行对照 iOS Demo：Utility.m - getCameraDataFromSampleBuffer:
  CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

  const size_t width = CVPixelBufferGetWidth(pixelBuffer);
  const size_t height = CVPixelBufferGetHeight(pixelBuffer);
  const OSType fmt = CVPixelBufferGetPixelFormatType(pixelBuffer);

  ASVLOFFSCREEN offscreen;
  memset(&offscreen, 0, sizeof(ASVLOFFSCREEN));

  // ✅ ArcSoft iOS SDK: NV12 对应 ASVL_PAF_NV12；BGRA 对应 ASVL_PAF_BGRA32
  if (fmt == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange ||
      fmt == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {

    offscreen.u32PixelArrayFormat = ASVL_PAF_NV12;
    offscreen.i32Width = (MInt32)width;
    offscreen.i32Height = (MInt32)height;

    const size_t yStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    const size_t uvStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);

    offscreen.pi32Pitch[0] = (MInt32)yStride;
    offscreen.pi32Pitch[1] = (MInt32)uvStride;

    uint8_t *yBase = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    uint8_t *uvBase = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);

    // Demo 里直接传指针也行；但 RN 多线程/生命周期复杂，这里复制一份，避免 pixelBuffer 解锁后指针失效。
    const size_t ySize = yStride * height;
    const size_t uvSize = uvStride * (height / 2);
    uint8_t *buf = (uint8_t *)malloc(ySize + uvSize);
    memcpy(buf, yBase, ySize);
    memcpy(buf + ySize, uvBase, uvSize);

    offscreen.ppu8Plane[0] = buf;
    offscreen.ppu8Plane[1] = buf + ySize;

  } else if (fmt == kCVPixelFormatType_32BGRA) {

    offscreen.u32PixelArrayFormat = ASVL_PAF_BGRA32;
    offscreen.i32Width = (MInt32)width;
    offscreen.i32Height = (MInt32)height;

    const size_t stride = CVPixelBufferGetBytesPerRow(pixelBuffer);
    offscreen.pi32Pitch[0] = (MInt32)stride;

    uint8_t *base = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);
    const size_t size = stride * height;
    uint8_t *buf = (uint8_t *)malloc(size);
    memcpy(buf, base, size);

    offscreen.ppu8Plane[0] = buf;

  } else {
    // 未支持格式：返回空 offscreen。
  }

  CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
  return offscreen;
}

+ (void)freeOffscreen:(ASVLOFFSCREEN *)offscreen {
  if (!offscreen) return;
  if (offscreen->ppu8Plane[0]) {
    free(offscreen->ppu8Plane[0]);
  }
  // plane[1] 是同一块内存的偏移，不需要单独 free
  offscreen->ppu8Plane[0] = NULL;
  offscreen->ppu8Plane[1] = NULL;
  offscreen->i32Width = 0;
  offscreen->i32Height = 0;
}

@end
