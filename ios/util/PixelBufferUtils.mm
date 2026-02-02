#import "PixelBufferUtils.h"
#import <CoreVideo/CoreVideo.h>

@implementation PixelBufferUtils

+ (NSData *)copyNV12Bytes:(CVPixelBufferRef)pixelBuffer width:(int *)outW height:(int *)outH {
  if (!pixelBuffer) return nil;

  OSType fmt = CVPixelBufferGetPixelFormatType(pixelBuffer);
  // 只处理 NV12
  if (fmt != kCVPixelFormatType_420YpCbCr8BiPlanarFullRange &&
      fmt != kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
    return nil;
  }

  CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

  const int w = (int)CVPixelBufferGetWidth(pixelBuffer);
  const int h = (int)CVPixelBufferGetHeight(pixelBuffer);

  const size_t yStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
  const size_t uvStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);

  uint8_t *yBase = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
  uint8_t *uvBase = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);

  NSMutableData *data = [NSMutableData dataWithLength:(size_t)(w * h + w * h / 2)];
  uint8_t *dst = (uint8_t *)data.mutableBytes;

  // copy Y
  for (int row = 0; row < h; row++) {
    memcpy(dst + row * w, yBase + row * yStride, (size_t)w);
  }

  // copy UV
  uint8_t *uvDst = dst + (size_t)(w * h);
  const int uvH = h / 2;
  for (int row = 0; row < uvH; row++) {
    memcpy(uvDst + row * w, uvBase + row * uvStride, (size_t)w);
  }

  CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

  if (outW) *outW = w;
  if (outH) *outH = h;
  return data;
}

@end
