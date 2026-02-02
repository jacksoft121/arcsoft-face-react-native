#import "PixelBufferUtils.h"
#import <CoreVideo/CoreVideo.h>
#import <ArcSoftFaceEngine/asvloffscreen.h>

@implementation PixelBufferUtils

+ (ASVLOFFSCREEN)offscreenFromPixelBuffer:(CVPixelBufferRef)pixelBuffer {
  CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

  size_t width = CVPixelBufferGetWidth(pixelBuffer);
  size_t height = CVPixelBufferGetHeight(pixelBuffer);

  void *yPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
  void *uvPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);

  ASVLOFFSCREEN offscreen = {0};
  offscreen.u32PixelArrayFormat = ASVL_PAF_NV12;
  offscreen.i32Width = (int)width;
  offscreen.i32Height = (int)height;
  offscreen.pi32Pitch[0] = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
  offscreen.pi32Pitch[1] = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
  offscreen.ppu8Plane[0] = (MUInt8 *)yPlane;
  offscreen.ppu8Plane[1] = (MUInt8 *)uvPlane;

  CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
  return offscreen;
}

@end
