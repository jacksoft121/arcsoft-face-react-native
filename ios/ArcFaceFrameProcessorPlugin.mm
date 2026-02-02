#import <VisionCamera/FrameProcessorPlugin.h>
#import <VisionCamera/FrameProcessorPluginRegistry.h>

#import "DetectEngine.h"
#import "FeatureEngine.h"
#import "FaceRegistry.h"

@interface ArcFaceFrameProcessorPlugin : FrameProcessorPlugin
@end

@implementation ArcFaceFrameProcessorPlugin

- (id)callback:(Frame *)frame withArguments:(NSDictionary *)args {
  CVPixelBufferRef buffer = frame.pixelBuffer;
  if (!buffer) return nil;

  NSString *action = args[@"action"] ?: @"process";
  NSString *userId = args[@"userId"];

  ASF_FaceInfo faceInfo = {0};
  [DetectEngine detectFromPixelBuffer:buffer faceInfo:&faceInfo];

  if (action && [action isEqualToString:@"register_from_frame"] && userId) {
    NSData *feature = [FeatureEngine extractFeatureFromPixelBuffer:buffer faceInfo:faceInfo];
    if (!feature) return nil;

    return @{
      @"type": @"register_result",
      @"userId": userId,
      @"featureBase64": [feature base64EncodedStringWithOptions:0],
      @"featureSize": @(feature.length)
    };
  }

  return @{
    @"type": @"process_result"
  };
}

@end

__attribute__((constructor))
static void registerArcFacePlugin() {
  [FrameProcessorPluginRegistry addFrameProcessorPlugin:@"arcFace"
    withInitializer:^FrameProcessorPlugin *(NSDictionary *options) {
      return [ArcFaceFrameProcessorPlugin new];
    }];
}
