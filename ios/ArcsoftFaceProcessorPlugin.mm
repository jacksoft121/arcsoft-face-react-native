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

  // Check arguments
  BOOL saveImage = NO;
  BOOL extractFeature = NO;
  if (arguments) {
      if (arguments[@"saveImage"]) saveImage = [arguments[@"saveImage"] boolValue];
      if (arguments[@"extractFeature"]) extractFeature = [arguments[@"extractFeature"] boolValue];
  }

  NSString *imagePath = nil;
  if (saveImage) {
      imagePath = [self saveFrame:pixelBuffer];
  }

  // Convert CVPixelBuffer to ASVLOFFSCREEN
  ASVLOFFSCREEN offscreen = [PixelBufferUtils offscreenFromPixelBuffer:pixelBuffer];

  NSArray<NSDictionary *> *faces = [[ArcsoftEngineManager sharedInstance] detectFaces:&offscreen];

  NSMutableArray *enrichedFaces = [NSMutableArray arrayWithCapacity:faces.count];
  for (NSDictionary *face in faces) {
      NSMutableDictionary *faceMutable = [face mutableCopy];
      if (extractFeature) {
          NSDictionary *rectDict = face[@"rect"];
          MRECT rect = {
              [rectDict[@"left"] intValue], [rectDict[@"top"] intValue],
              [rectDict[@"right"] intValue], [rectDict[@"bottom"] intValue]
          };
          int orient = [face[@"orient"] intValue];

          NSString *featBase64 = [[ArcsoftEngineManager sharedInstance] extractFeature:&offscreen faceRect:rect orient:orient];
          if (featBase64) {
              faceMutable[@"featureBase64"] = featBase64;
          }
      }
      [enrichedFaces addObject:faceMutable];
  }

  [PixelBufferUtils freeOffscreen:&offscreen];

  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  result[@"faces"] = enrichedFaces;
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

    // Save to Documents directory for easier access via iTunes File Sharing
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:fileName];

    if ([data writeToFile:path atomically:YES]) {
        NSLog(@"[ArcsoftFace] Saved frame to %@", path);
        return [@"file://" stringByAppendingString:path];
    }
    return nil;
}

VISION_EXPORT_FRAME_PROCESSOR(ArcsoftFaceProcessorPlugin, detectFaces)

@end
