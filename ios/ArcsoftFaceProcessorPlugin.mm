#import <VisionCamera/FrameProcessorPlugin.h>
#import <VisionCamera/FrameProcessorPluginRegistry.h>
#import <VisionCamera/Frame.h>
#import "ArcsoftEngineManager.h"
#import "PixelBufferUtils.h"

@interface ArcsoftFaceProcessorPlugin : FrameProcessorPlugin
@end

@implementation ArcsoftFaceProcessorPlugin

- (instancetype)initWithProxy:(VisionCameraProxyHolder*)proxy
                  withOptions:(NSDictionary* _Nullable)options {
  if (self = [super initWithProxy:proxy withOptions:options]) {
    // init
  }
  return self;
}

- (id)callback:(Frame*)frame withArguments:(NSDictionary* _Nullable)arguments {
  CMSampleBufferRef buffer = frame.buffer;
  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(buffer);

  if (!pixelBuffer) return nil;

  // Convert CVPixelBuffer to ASVLOFFSCREEN
  ASVLOFFSCREEN offscreen = [PixelBufferUtils offscreenFromPixelBuffer:pixelBuffer];

  NSArray<NSDictionary *> *faces = [[ArcsoftEngineManager shared] detectFaces:&offscreen];

  [PixelBufferUtils freeOffscreen:&offscreen];

  return faces;
}

@end

VISION_EXPORT_FRAME_PROCESSOR(ArcsoftFaceProcessorPlugin, detectFaces)
