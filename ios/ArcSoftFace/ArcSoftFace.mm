#import "ArcSoftFace.h"

#import <React/RCTLog.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import <React/RCTTurboModule.h>
#endif

#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngineDefine.h>

static inline int ASFImageFormatFromString(NSString *s) {
  if ([s isEqualToString:@"ASF_IMAGE_FORMAT_BGR24"]) return ASF_IMAGE_FORMAT_BGR24;
  if ([s isEqualToString:@"ASF_IMAGE_FORMAT_BGRA32"]) return ASF_IMAGE_FORMAT_BGRA32;
  if ([s isEqualToString:@"ASF_IMAGE_FORMAT_GRAY"]) return ASF_IMAGE_FORMAT_GRAY;
  if ([s isEqualToString:@"ASF_IMAGE_FORMAT_NV21"]) return ASF_IMAGE_FORMAT_NV21;
  return ASF_IMAGE_FORMAT_BGRA32;
}

static inline int ASFDetectModeFromString(NSString *s) {
  if ([s isEqualToString:@"ASF_DETECT_MODE_IMAGE"]) return ASF_DETECT_MODE_IMAGE;
  return ASF_DETECT_MODE_VIDEO;
}

static inline int ASFOrientPriorityFromString(NSString *s) {
  if ([s isEqualToString:@"ASF_OP_0_ONLY"]) return ASF_OP_0_ONLY;
  if ([s isEqualToString:@"ASF_OP_90_ONLY"]) return ASF_OP_90_ONLY;
  if ([s isEqualToString:@"ASF_OP_270_ONLY"]) return ASF_OP_270_ONLY;
  if ([s isEqualToString:@"ASF_OP_180_ONLY"]) return ASF_OP_180_ONLY;
  if ([s isEqualToString:@"ASF_OP_0_HIGHER_EXT"]) return ASF_OP_0_HIGHER_EXT;
  if ([s isEqualToString:@"ASF_OP_90_HIGHER_EXT"]) return ASF_OP_90_HIGHER_EXT;
  if ([s isEqualToString:@"ASF_OP_270_HIGHER_EXT"]) return ASF_OP_270_HIGHER_EXT;
  if ([s isEqualToString:@"ASF_OP_180_HIGHER_EXT"]) return ASF_OP_180_HIGHER_EXT;
  return ASF_OP_0_HIGHER_EXT;
}

static inline NSData * _Nullable DataFromBase64(NSString *base64) {
  if (base64.length == 0) return nil;
  return [[NSData alloc] initWithBase64EncodedString:base64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

static inline NSDictionary *FaceRectToDict(MRECT rect) {
  return @{ @"left": @(rect.left), @"top": @(rect.top), @"right": @(rect.right), @"bottom": @(rect.bottom) };
}

static inline NSDictionary *SingleFaceToDict(ASF_SingleFaceInfo face) {
  return @{ @"rect": FaceRectToDict(face.faceRect), @"orient": @(face.faceOrient) };
}

static inline ASF_SingleFaceInfo DictToSingleFace(NSDictionary *d) {
  ASF_SingleFaceInfo f;
  NSDictionary *r = d[@"rect"];
  f.faceRect.left = [r[@"left"] intValue];
  f.faceRect.top = [r[@"top"] intValue];
  f.faceRect.right = [r[@"right"] intValue];
  f.faceRect.bottom = [r[@"bottom"] intValue];
  f.faceOrient = [d[@"orient"] intValue];
  return f;
}

@interface ArcSoftFace ()
@property(nonatomic, strong, nullable) ArcSoftFaceEngine *engine;
@end

@implementation ArcSoftFace

#ifndef RCT_NEW_ARCH_ENABLED
RCT_EXPORT_MODULE(ArcSoftFace)
#endif

+ (BOOL)requiresMainQueueSetup { return NO; }

- (ArcSoftFaceEngine *)ensureEngine {
  if (!self.engine) self.engine = [[ArcSoftFaceEngine alloc] init];
  return self.engine;
}

#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeArcFaceSpecJSI>(params);
}
#endif

#pragma mark - init/uninit

- (void)init:(NSDictionary *)config resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  NSString *appId = config[@"appId"] ?: @"";
  NSString *sdkKey = config[@"sdkKey"] ?: @"";
  if (appId.length == 0 || sdkKey.length == 0) {
    reject(@"E_INIT", @"appId/sdkKey required", nil);
    return;
  }

  int detectMode = ASFDetectModeFromString(config[@"detectMode"] ?: @"ASF_DETECT_MODE_VIDEO");
  int orient = ASFOrientPriorityFromString(config[@"orientationPriority"] ?: @"ASF_OP_0_HIGHER_EXT");
  int scale = config[@"scale"] ? [config[@"scale"] intValue] : 16;
  int maxFaceNum = config[@"maxFaceNum"] ? [config[@"maxFaceNum"] intValue] : 5;
  int combinedMask = config[@"combinedMask"] ? [config[@"combinedMask"] intValue]
    : (ASF_FACE_DETECT | ASF_FACERECOGNITION | ASF_AGE | ASF_GENDER | ASF_FACE3DANGLE | ASF_LIVENESS);

  ArcSoftFaceEngine *engine = [self ensureEngine];
  MRESULT ret = [engine initWithAppId:appId
                               sdkKey:sdkKey
                            detectMode:detectMode
                        orientPriority:orient
                                 scale:scale
                            maxFaceNum:maxFaceNum
                          combinedMask:combinedMask];
  resolve(@(ret));
}

- (void)unInit:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  if (!self.engine) { resolve(@(MOK)); return; }
  MRESULT ret = [self.engine unInit];
  self.engine = nil;
  resolve(@(ret));
}

- (void)getVersion:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  ArcSoftFaceEngine *engine = [self ensureEngine];
  ASF_Version v = [engine getVersion];
  NSString *ver = [NSString stringWithFormat:@"%@ | %@ | %@", v.version, v.buildDate, v.copyRight];
  resolve(ver);
}

#pragma mark - detect

- (void)detectFaces:(NSDictionary *)image resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  ArcSoftFaceEngine *engine = [self ensureEngine];

  int width = [image[@"width"] intValue];
  int height = [image[@"height"] intValue];
  int format = ASFImageFormatFromString(image[@"format"] ?: @"ASF_IMAGE_FORMAT_BGRA32");
  NSData *data = DataFromBase64(image[@"base64"] ?: @"");
  if (!data) { reject(@"E_IMAGE", @"base64 image bytes required", nil); return; }

  ASF_MultiFaceInfo faces = {0};
  MRESULT ret = [engine detectFacesWithWidth:width height:height format:format data:(MUInt8 *)data.bytes faceInfo:&faces];
  if (ret != MOK) { resolve(@{ @"faces": @[], @"code": @(ret) }); return; }

  NSMutableArray *arr = [NSMutableArray array];
  for (int i=0; i<faces.faceNum; i++) {
    ASF_SingleFaceInfo f;
    f.faceRect = faces.faceRects[i];
    f.faceOrient = faces.faceOrients[i];
    [arr addObject:SingleFaceToDict(f)];
  }
  resolve(@{ @"faces": arr });
}

#pragma mark - process

- (void)process:(NSDictionary *)image
          faces:(NSArray *)faces
           mask:(NSDictionary *)mask
        resolve:(RCTPromiseResolveBlock)resolve
         reject:(RCTPromiseRejectBlock)reject {

  ArcSoftFaceEngine *engine = [self ensureEngine];

  int width = [image[@"width"] intValue];
  int height = [image[@"height"] intValue];
  int format = ASFImageFormatFromString(image[@"format"] ?: @"ASF_IMAGE_FORMAT_BGRA32");
  NSData *data = DataFromBase64(image[@"base64"] ?: @"");
  if (!data) { reject(@"E_IMAGE", @"base64 image bytes required", nil); return; }

  int faceNum = (int)faces.count;
  if (faceNum <= 0) { resolve(@{}); return; }

  std::vector<MRECT> rects(faceNum);
  std::vector<MInt32> orients(faceNum);
  for (int i=0; i<faceNum; i++) {
    ASF_SingleFaceInfo f = DictToSingleFace(faces[i]);
    rects[i] = f.faceRect;
    orients[i] = f.faceOrient;
  }

  ASF_MultiFaceInfo m;
  memset(&m, 0, sizeof(m));
  m.faceNum = faceNum;
  m.faceRects = rects.data();
  m.faceOrients = orients.data();

  int combinedMask = 0;
  if ([mask[@"age"] boolValue]) combinedMask |= ASF_AGE;
  if ([mask[@"gender"] boolValue]) combinedMask |= ASF_GENDER;
  if ([mask[@"face3dAngle"] boolValue]) combinedMask |= ASF_FACE3DANGLE;
  if ([mask[@"liveness"] boolValue]) combinedMask |= ASF_LIVENESS;

  MRESULT ret = [engine processWithWidth:width height:height format:format data:(MUInt8 *)data.bytes faceInfo:&m combinedMask:combinedMask];
  if (ret != MOK) { resolve(@{ @"code": @(ret) }); return; }

  NSMutableDictionary *out = [NSMutableDictionary dictionary];

  if (combinedMask & ASF_AGE) {
    ASF_AgeInfo ageInfo = {0};
    if ([engine getAge:&ageInfo] == MOK && ageInfo.num == faceNum) {
      NSMutableArray *ages = [NSMutableArray arrayWithCapacity:faceNum];
      for (int i=0;i<faceNum;i++) [ages addObject:@(ageInfo.ageArray[i])];
      out[@"ages"] = ages;
    }
  }

  if (combinedMask & ASF_GENDER) {
    ASF_GenderInfo genderInfo = {0};
    if ([engine getGender:&genderInfo] == MOK && genderInfo.num == faceNum) {
      NSMutableArray *genders = [NSMutableArray arrayWithCapacity:faceNum];
      for (int i=0;i<faceNum;i++) [genders addObject:@(genderInfo.genderArray[i])];
      out[@"genders"] = genders;
    }
  }

  if (combinedMask & ASF_LIVENESS) {
    ASF_LivenessInfo live = {0};
    if ([engine getLiveness:&live] == MOK && live.num == faceNum) {
      NSMutableArray *scores = [NSMutableArray arrayWithCapacity:faceNum];
      for (int i=0;i<faceNum;i++) [scores addObject:@(live.livenessScore[i])];
      out[@"livenessScores"] = scores;
    }
  }

  if (combinedMask & ASF_FACE3DANGLE) {
    ASF_Face3DAngle face3d = {0};
    if ([engine getFace3DAngle:&face3d] == MOK && face3d.num == faceNum) {
      NSMutableArray *angles = [NSMutableArray arrayWithCapacity:faceNum];
      for (int i=0;i<faceNum;i++) {
        [angles addObject:@{ @"pitch": @(face3d.pitch[i]), @"roll": @(face3d.roll[i]), @"yaw": @(face3d.yaw[i]), @"status": @(face3d.status[i]) }];
      }
      out[@"face3dAngles"] = angles;
    }
  }

  resolve(out);
}

#pragma mark - liveness threshold

- (void)setLivenessThreshold:(double)threshold resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  ArcSoftFaceEngine *engine = [self ensureEngine];
  ASF_LivenessThreshold t;
  t.thresholdmodel_BGR = (MFloat)threshold;
  t.thresholdmodel_IR = (MFloat)threshold;
  MRESULT ret = [engine setLivenessThreshold:&t];
  resolve(@(ret));
}

- (void)getLivenessThreshold:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  ArcSoftFaceEngine *engine = [self ensureEngine];
  ASF_LivenessThreshold t = {0};
  MRESULT ret = [engine getLivenessThreshold:&t];
  if (ret != MOK) { resolve(@(0)); return; }
  resolve(@(t.thresholdmodel_BGR));
}

#pragma mark - feature

- (void)extractFeature:(NSDictionary *)image face:(NSDictionary *)face resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  ArcSoftFaceEngine *engine = [self ensureEngine];

  int width = [image[@"width"] intValue];
  int height = [image[@"height"] intValue];
  int format = ASFImageFormatFromString(image[@"format"] ?: @"ASF_IMAGE_FORMAT_BGRA32");
  NSData *data = DataFromBase64(image[@"base64"] ?: @"");
  if (!data) { reject(@"E_IMAGE", @"base64 image bytes required", nil); return; }

  ASF_SingleFaceInfo f = DictToSingleFace(face);

  ASF_FaceFeature feat = {0};
  MRESULT ret = [engine extractFaceFeatureWithWidth:width height:height format:format data:(MUInt8 *)data.bytes singleFaceInfo:&f faceFeature:&feat];
  if (ret != MOK) { resolve(@{ @"base64": @"", @"size": @(0), @"code": @(ret) }); return; }

  NSData *featData = [NSData dataWithBytes:feat.feature length:feat.featureSize];
  NSString *b64 = [featData base64EncodedStringWithOptions:0];
  resolve(@{ @"base64": b64, @"size": @(feat.featureSize) });
}

- (void)compareFeature:(NSDictionary *)feature1 feature2:(NSDictionary *)feature2 compareModel:(double)compareModel resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  ArcSoftFaceEngine *engine = [self ensureEngine];

  NSData *d1 = DataFromBase64(feature1[@"base64"] ?: @"");
  NSData *d2 = DataFromBase64(feature2[@"base64"] ?: @"");
  if (!d1 || !d2) { reject(@"E_FEATURE", @"feature base64 required", nil); return; }

  ASF_FaceFeature f1; f1.featureSize = (MInt32)d1.length; f1.feature = (MByte *)d1.bytes;
  ASF_FaceFeature f2; f2.featureSize = (MInt32)d2.length; f2.feature = (MByte *)d2.bytes;

  MFloat sim = 0.0f;
  MRESULT ret = [engine compareFaceFeature:&f1 faceFeature2:&f2 compareModel:(MInt32)compareModel confidenceLevel:&sim];
  if (ret != MOK) { resolve(@(-1)); return; }
  resolve(@(sim));
}

#pragma mark - liveness interactive / glare

- (void)detectLivenessInteractive:(NSDictionary *)image face:(NSDictionary *)face action:(double)action reset:(double)reset resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  ArcSoftFaceEngine *engine = [self ensureEngine];

  int width = [image[@"width"] intValue];
  int height = [image[@"height"] intValue];
  int format = ASFImageFormatFromString(image[@"format"] ?: @"ASF_IMAGE_FORMAT_BGRA32");
  NSData *data = DataFromBase64(image[@"base64"] ?: @"");
  if (!data) { reject(@"E_IMAGE", @"base64 image bytes required", nil); return; }

  ASF_SingleFaceInfo f = DictToSingleFace(face);
  ASF_LivenessResult r = {0};

  MRESULT ret = [engine detectLivenessInteractiveWithWidth:width height:height format:format data:(MUInt8 *)data.bytes singleFaceInfo:&f action:(MInt32)action resetOpt:(MInt32)reset livenessResult:&r];
  resolve(@{ @"result": @(r.iResult), @"action": @(r.iAction), @"status": @(ret) });
}

- (void)detectLivenessGlare:(NSDictionary *)image face:(NSDictionary *)face flashSequenceMode:(double)flashSequenceMode flashColor:(double)flashColor reset:(double)reset resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  ArcSoftFaceEngine *engine = [self ensureEngine];

  int width = [image[@"width"] intValue];
  int height = [image[@"height"] intValue];
  int format = ASFImageFormatFromString(image[@"format"] ?: @"ASF_IMAGE_FORMAT_BGRA32");
  NSData *data = DataFromBase64(image[@"base64"] ?: @"");
  if (!data) { reject(@"E_IMAGE", @"base64 image bytes required", nil); return; }

  ASF_SingleFaceInfo f = DictToSingleFace(face);
  ASF_LivenessResult r = {0};

  MRESULT ret = [engine detectLivenessGlareWithWidth:width height:height format:format data:(MUInt8 *)data.bytes singleFaceInfo:&f flashSequence:(MInt32)flashSequenceMode color:(MInt32)flashColor resetOpt:(MInt32)reset livenessResult:&r];
  resolve(@{ @"result": @(r.iResult), @"action": @(r.iAction), @"status": @(ret) });
}

@end
