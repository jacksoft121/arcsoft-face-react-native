#import "DetectEngine.h"
#import "ArcFaceEnginePool.h"
#import "PixelBufferUtils.h"

@implementation DetectEngine

+ (ASF_FaceFeature *)detectFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                 faceInfo:(ASF_FaceInfo *)outFaceInfo {
  __block ASF_FaceFeature *result = nil;

  [ArcFaceEnginePool withDetectEngine:^(ASF_FaceEngine engine) {
    ASVLOFFSCREEN offscreen = [PixelBufferUtils offscreenFromPixelBuffer:pixelBuffer];

    ASF_MultiFaceInfo faces = {0};
    ASFDetectFaces(engine, &offscreen, &faces);

    if (faces.faceNum < 1) return;

    *outFaceInfo = faces.faceInfos[0];
  }];

  return result;
}

@end
