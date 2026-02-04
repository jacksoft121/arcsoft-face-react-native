#import "ArcsoftFaceModule.h"
#import <React/RCTUtils.h>

#ifndef RCT_NEW_ARCH_ENABLED
#import <React/RCTBridge.h>
#import <React/RCTBridgeModule.h>
#endif

#import "ArcsoftEngineManager.h"
#import "ArcsoftFaceDB.h"

/// 注意：不打包 ArcSoftFaceEngine.framework，本插件只引用其头文件。
/// 你需要在 App 工程里按官方文档把 ArcSoftFaceEngine.framework 加入：
/// - iOS Demo 对照：ArcSoftFaceEngineDemo.xcodeproj 的 Frameworks 配置。

@interface ArcsoftFaceModule ()
@property(nonatomic, strong) ArcsoftEngineManager *engineManager;
@property(nonatomic, strong) ArcsoftFaceDB *faceDB;
@end

@implementation ArcsoftFaceModule

RCT_EXTERN_METHOD(dummy)

+ (BOOL)requiresMainQueueSetup {
  return NO;
}

- (instancetype)init {
  if (self = [super init]) {
    _engineManager = [[ArcsoftEngineManager alloc] init];
    _faceDB = [[ArcsoftFaceDB alloc] init];
  }
  return self;
}

#ifndef RCT_NEW_ARCH_ENABLED
RCT_EXPORT_MODULE(ArcsoftFace)
#else
// TurboModule name is derived from codegen spec (NativeArcsoftFaceSpec)
// default is the JS module name "ArcsoftFace"
#endif

#pragma mark - Helpers

static NSData * _Nullable DataFromBase64(NSString * _Nullable base64) {
  if (base64 == nil) return nil;
  return [[NSData alloc] initWithBase64EncodedString:base64 options:0];
}

static NSString * Base64FromData(NSData *data) {
  return [data base64EncodedStringWithOptions:0];
}

#pragma mark - Public API (aligned with TS spec)

RCT_EXPORT_METHOD(activateOnline:(NSString *)appId
                  sdkKey:(NSString *)sdkKey
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  // iOS SDK：在线激活接口在 ArcSoftFaceEngine.h
  MRESULT code = [ArcSoftFaceEngine activeOnlineWithAppId:appId sdkKey:sdkKey];
  if (code == MOK) {
    resolve(@(YES));
  } else {
    reject(@"ACTIVATE_FAILED", [NSString stringWithFormat:@"ArcSoft iOS activateOnline failed: %d", (int)code], nil);
  }
}

RCT_EXPORT_METHOD(initEngine:(NSDictionary *)options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  NSString *appId = options[@"appId"] ?: @"";
  NSString *sdkKey = options[@"sdkKey"] ?: @"";
  NSNumber *mask = options[@"combinedMask"] ?: @(ASF_FACE_DETECT);

  MRESULT code = [self.engineManager initEngineWithAppId:appId sdkKey:sdkKey combinedMask:[mask intValue]];
  if (code == MOK) {
    resolve(@(YES));
  } else {
    reject(@"INIT_FAILED", [NSString stringWithFormat:@"ArcSoft iOS initEngine failed: %d", (int)code], nil);
  }
}

RCT_EXPORT_METHOD(unInitEngine:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [self.engineManager unInitEngine];
  resolve(@(YES));
}

RCT_EXPORT_METHOD(detectFaces:(NSDictionary *)image
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  NSData *data = DataFromBase64(image[@"data"]);
  if (!data) {
    reject(@"BAD_IMAGE", @"image.data (base64) is required", nil);
    return;
  }

  int width = [image[@"width"] intValue];
  int height = [image[@"height"] intValue];
  NSString *formatStr = image[@"format"] ?: @"NV21";

  NSArray<NSDictionary *> *faces = [self.engineManager detectFacesWithData:data width:width height:height format:formatStr];
  resolve(@{ @"faces": faces });
}

RCT_EXPORT_METHOD(extractFeature:(NSDictionary *)image
                  faceIndex:(double)faceIndex
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  NSData *data = DataFromBase64(image[@"data"]);
  if (!data) {
    reject(@"BAD_IMAGE", @"image.data (base64) is required", nil);
    return;
  }
  int width = [image[@"width"] intValue];
  int height = [image[@"height"] intValue];
  NSString *formatStr = image[@"format"] ?: @"NV21";

  NSData *feat = [self.engineManager extractFeatureWithData:data width:width height:height format:formatStr faceIndex:(NSInteger)faceIndex];
  if (!feat) {
    resolve([NSNull null]);
    return;
  }
  resolve(@{ @"dataBase64": Base64FromData(feat) });
}

RCT_EXPORT_METHOD(compareFeature:(NSDictionary *)f1
                  f2:(NSDictionary *)f2
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  NSData *d1 = DataFromBase64(f1[@"dataBase64"]);
  NSData *d2 = DataFromBase64(f2[@"dataBase64"]);
  if (!d1 || !d2) {
    reject(@"BAD_FEATURE", @"f1.dataBase64 and f2.dataBase64 are required", nil);
    return;
  }

  float score = [self.engineManager compareFeatureData:d1 with:d2];
  resolve(@(score));
}

RCT_EXPORT_METHOD(processAttributes:(NSDictionary *)image
                  faceIndexes:(NSArray<NSNumber *> *)faceIndexes
                  needAge:(BOOL)needAge
                  needGender:(BOOL)needGender
                  needLiveness:(BOOL)needLiveness
                  need3DAngle:(BOOL)need3DAngle
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  NSData *data = DataFromBase64(image[@"data"]);
  if (!data) {
    reject(@"BAD_IMAGE", @"image.data (base64) is required", nil);
    return;
  }
  int width = [image[@"width"] intValue];
  int height = [image[@"height"] intValue];
  NSString *formatStr = image[@"format"] ?: @"NV21";

  NSDictionary *out = [self.engineManager processAttributesWithData:data
                                                             width:width
                                                            height:height
                                                            format:formatStr
                                                       faceIndexes:faceIndexes
                                                           needAge:needAge
                                                        needGender:needGender
                                                      needLiveness:needLiveness
                                                       need3DAngle:need3DAngle];
  resolve(out);
}

RCT_EXPORT_METHOD(dbUpsert:(NSString *)userId
                  feature:(NSDictionary *)feature
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  NSData *d = DataFromBase64(feature[@"dataBase64"]);
  if (!d) {
    reject(@"BAD_FEATURE", @"feature.dataBase64 required", nil);
    return;
  }

  // iOS：用 ArcSoftFaceFeature 结构体封装 bytes
  ArcSoftFaceFeature *f = [[ArcSoftFaceFeature alloc] init];
  // ArcSoftFaceFeature 的 bytes setter 在 SDK 内部实现；这里用 initWithData
  // 若你的 SDK 版本没有该 init，请按 Demo 的 featureInfo.feature 赋值方式改。
  if ([f respondsToSelector:@selector(setFeatureData:)]) {
    [f performSelector:@selector(setFeatureData:) withObject:d];
  } else {
    // 兜底：用 KVC 试图写入
    @try { [f setValue:d forKey:@"featureData"]; } @catch(__unused NSException *e) {}
  }

  [self.faceDB upsertFeature:f forUserId:userId];
  resolve(@(YES));
}

RCT_EXPORT_METHOD(dbRemove:(NSString *)userId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [self.faceDB removeFeatureForUserId:userId];
  resolve(@(YES));
}

RCT_EXPORT_METHOD(dbSearch:(NSDictionary *)feature
                  topK:(double)topK
                  threshold:(double)threshold
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  NSData *d = DataFromBase64(feature[@"dataBase64"]);
  if (!d) {
    reject(@"BAD_FEATURE", @"feature.dataBase64 required", nil);
    return;
  }

  NSArray *results = [self.faceDB searchWithEngine:self.engineManager.engine featureData:d topK:(NSInteger)topK threshold:(float)threshold];
  resolve(results);
}

RCT_EXPORT_METHOD(dbClear:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [self.faceDB clear];
  resolve(@(YES));
}

@end
