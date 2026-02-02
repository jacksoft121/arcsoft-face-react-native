#import "ArcFaceEnginePool.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngineDefine.h>

@implementation ArcFaceEnginePool

+ (ArcSoftFaceEngine *)detectEngine {
  static ArcSoftFaceEngine *engine = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    engine = [[ArcSoftFaceEngine alloc] init];
    // VIDEO: 更适合连续帧（追踪平滑、速度更快）:contentReference[oaicite:2]{index=2}
    MInt32 mask = ASF_FACE_DETECT | ASF_FACERECOGNITION;
    [engine initFaceEngineWithDetectMode:ASF_DETECT_MODE_VIDEO
                           orientPriority:ASF_OP_0_ONLY
                               maxFaceNum:1
                             combinedMask:mask];
  });
  return engine;
}

+ (ArcSoftFaceEngine *)featureEngine {
  static ArcSoftFaceEngine *engine = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    engine = [[ArcSoftFaceEngine alloc] init];
    // IMAGE: 静态图精度更高，适合注册/提特征:contentReference[oaicite:3]{index=3}
    MInt32 mask = ASF_FACE_DETECT | ASF_FACERECOGNITION;
    [engine initFaceEngineWithDetectMode:ASF_DETECT_MODE_IMAGE
                           orientPriority:ASF_OP_0_ONLY
                               maxFaceNum:1
                             combinedMask:mask];
  });
  return engine;
}

@end
