#import "ArcFaceEnginePool.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>

static dispatch_queue_t detectQueue;
static dispatch_queue_t featureQueue;

static ASF_FaceEngine detectEngine = nullptr;
static ASF_FaceEngine featureEngine = nullptr;

@implementation ArcFaceEnginePool

+ (void)initialize {
  if (self == [ArcFaceEnginePool class]) {
    detectQueue = dispatch_queue_create("arcface.detect.queue", DISPATCH_QUEUE_SERIAL);
    featureQueue = dispatch_queue_create("arcface.feature.queue", DISPATCH_QUEUE_SERIAL);
  }
}

+ (void)initEnginesIfNeeded {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // VIDEO engine（实时）
    ASFInitEngine(
      ASF_DETECT_MODE_VIDEO,
      ASF_OP_0_ONLY,
      16,
      1,
      ASF_FACE_DETECT | ASF_FACE_RECOGNITION,
      &detectEngine
    );

    // IMAGE engine（注册/提特征）
    ASFInitEngine(
      ASF_DETECT_MODE_IMAGE,
      ASF_OP_0_ONLY,
      30,
      1,
      ASF_FACE_DETECT | ASF_FACE_RECOGNITION,
      &featureEngine
    );
  });
}

+ (void)withDetectEngine:(void (^)(ASF_FaceEngine engine))block {
  [self initEnginesIfNeeded];
  dispatch_sync(detectQueue, ^{
    block(detectEngine);
  });
}

+ (void)withFeatureEngine:(void (^)(ASF_FaceEngine engine))block {
  [self initEnginesIfNeeded];
  dispatch_sync(featureQueue, ^{
    block(featureEngine);
  });
}

@end
