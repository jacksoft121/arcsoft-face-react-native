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

  // Check saveImage argument
  BOOL saveImage = NO;
  if (arguments && arguments[@"saveImage"]) {
      saveImage = [arguments[@"saveImage"] boolValue];
  }

  NSString *imagePath = nil;
  if (saveImage) {
      imagePath = [self saveFrame:pixelBuffer];
  }

  // Convert CVPixelBuffer to ASVLOFFSCREEN
  ASVLOFFSCREEN offscreen = [PixelBufferUtils offscreenFromPixelBuffer:pixelBuffer];

  NSArray<NSDictionary *> *faces = [[ArcsoftEngineManager shared] detectFaces:&offscreen];

  [PixelBufferUtils freeOffscreen:&offscreen];

  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  result[@"faces"] = faces;
  if (imagePath) {
      result[@"imagePath"] = imagePath;
  }

  return result;
}

- (NSString *)saveFrame:(CVPixelBufferRef)pixelBuffer {
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CIContext *context = [CIContext context];
    CGImageRef cgImage = [context createCGImage:ciImage fromRect:[ciImage extent]];
    UIImage *uiImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);

    NSData *data = UIImageJPEGRepresentation(uiImage, 0.8);
    NSString *fileName = [NSString stringWithFormat:@"face_%f.jpg", [[NSDate date] timeIntervalSince1970]];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];

    if ([data writeToFile:path atomically:YES]) {
        NSLog(@"[ArcsoftFace] Saved frame to %@", path);
        return path; // Return path without file:// prefix usually, or with it? RN usually likes file://
        // Let's return absolute path, JS can prepend file:// if needed, or we do it here.
        return [@"file://" stringByAppendingString:path];
    }
    return nil;
}

@end

VISION_EXPORT_FRAME_PROCESSOR(ArcsoftFaceProcessorPlugin, detectFaces)
