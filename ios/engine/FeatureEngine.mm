#import "FeatureEngine.h"
#import "ArcFaceEnginePool.h"
#import "PixelBufferUtils.h"

@implementation FeatureEngine

+ (NSData *)extractFeatureFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                 faceInfo:(ASF_FaceInfo)faceInfo {
  __block NSData *featureData = nil;

  [ArcFaceEnginePool withFeatureEngine:^(ASF_FaceEngine engine) {
    ASVLOFFSCREEN offscreen = [PixelBufferUtils offscreenFromPixelBuffer:pixelBuffer];

    ASF_FaceFeature feature = {0};
    if (ASFExtractFaceFeature(engine, &offscreen, &faceInfo, &feature) != MOK) {
      return;
    }

    featureData = [NSData dataWithBytes:feature.featureData length:feature.featureSize];
  }];

  return featureData;
}

@end
