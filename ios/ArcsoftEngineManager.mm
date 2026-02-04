#import "ArcsoftEngineManager.h"

/// 逐行对照官方 iOS Demo：
/// - engine/ASFVideoProcessor.m
/// - engine/ASFImageProcessor.m
/// - util/Utility.m

@interface ArcsoftEngineManager ()
@property(nonatomic, readwrite) BOOL inited;
@property(nonatomic, strong, readwrite) ArcSoftFaceEngine *engine;
@property(nonatomic, assign) int combinedMask;
@property(nonatomic, strong) NSArray<NSDictionary *> *lastFace3DAngles;
@end

@implementation ArcsoftEngineManager

- (instancetype)init {
  if (self = [super init]) {
    _engine = [[ArcSoftFaceEngine alloc] init];
    _inited = NO;
    _combinedMask = 0;
    _lastFace3DAngles = @[];
  }
  return self;
}

- (int)activateWithAppId:(NSString *)appId
                 sdkKey:(NSString *)sdkKey
              activeKey:(NSString *)activeKey {
  // 对照 Demo：通常在 App 启动时调用激活接口。
  // 不同 SDK 版本可能是 online/offline/activeKey 三种方式。
  // 这里采取“尽可能兼容”的调用：优先带 activeKey（如果框架提供），否则仅 appId+sdkKey。

  // 绝大多数版本都有：activeWithAppId:SDKKey:
  if ([self.engine respondsToSelector:@selector(activeWithAppId:SDKKey:)]) {
    return [self.engine activeWithAppId:appId SDKKey:sdkKey];
  }

  // 若你的版本是离线激活，请在此处按官方 Demo 替换（比如 activeOffline:）
  return -1;
}

- (int)initEngineWithDetectMode:(ASF_DetectMode)detectMode
                 orientPriority:(ASF_OrientPriority)orientPriority
                     maxFaceNum:(int)maxFaceNum
                   combinedMask:(int)combinedMask {
  // 对照 Demo：initEngine
  self.combinedMask = combinedMask;
  int code = [self.engine initFaceEngineWithDetectMode:detectMode
                             orientPriority:orientPriority
                                 maxFaceNum:maxFaceNum
                               combinedMask:combinedMask];
  self.inited = (code == MOK);
  return code;
}

- (void)uninit {
  if (self.inited) {
    [self.engine unInitFaceEngine];
    self.inited = NO;
  }
}

- (NSArray<NSDictionary *> *)detectFaces:(ASVLOFFSCREEN *)offscreen {
  if (!self.inited || offscreen == NULL) return @[];

  ASF_MultiFaceInfo faces = {0};
  MRESULT result = [self.engine detectFacesWithWidth:offscreen->i32Width
                                              height:offscreen->i32Height
                                                data:offscreen->ppu8Plane[0]
                                              format:offscreen->u32PixelArrayFormat
                                             faceRes:&faces];

  if (result != MOK) {
      return @[];
  }

  // Cache 3D angles
  NSMutableArray *angles = [NSMutableArray arrayWithCapacity:faces.faceNum];
  if (faces.face3DAngleInfo.yaw && faces.face3DAngleInfo.pitch && faces.face3DAngleInfo.roll) {
      for (int i = 0; i < faces.faceNum; i++) {
          [angles addObject:@{
              @"yaw": @(faces.face3DAngleInfo.yaw[i]),
              @"pitch": @(faces.face3DAngleInfo.pitch[i]),
              @"roll": @(faces.face3DAngleInfo.roll[i]),
              @"status": @(0) // Status removed in new SDK
          }];
      }
  }
  self.lastFace3DAngles = angles;

  // Process Age, Gender, Liveness if requested
  int processMask = self.combinedMask & (ASF_AGE | ASF_GENDER | ASF_LIVENESS);
  if (processMask != 0 && faces.faceNum > 0) {
      [self.engine processWithWidth:offscreen->i32Width
                             height:offscreen->i32Height
                               data:offscreen->ppu8Plane[0]
                             format:offscreen->u32PixelArrayFormat
                            faceRes:&faces
                               mask:processMask];
  }

  NSMutableArray *out = [NSMutableArray arrayWithCapacity:faces.faceNum];
  for (int i = 0; i < faces.faceNum; i++) {
    MRECT r = faces.faceRect[i];
    [out addObject:@{
      @"rect": @{
        @"left": @(r.left),
        @"top": @(r.top),
        @"right": @(r.right),
        @"bottom": @(r.bottom),
      },
      @"orient": @(faces.faceOrient[i]),
    }];
  }
  return out;
}

- (NSString *)extractFeature:(ASVLOFFSCREEN *)offscreen
                    faceRect:(MRECT)rect
                      orient:(int)orient {
  if (!self.inited || offscreen == NULL) return nil;

  ASF_SingleFaceInfo info = {0};
  info.faceRect = rect;
  info.faceOrient = orient;

  ASF_FaceFeature feature = {0};
  MRESULT result = [self.engine extractFaceFeatureWithWidth:offscreen->i32Width
                                                     height:offscreen->i32Height
                                                       data:offscreen->ppu8Plane[0]
                                                     format:offscreen->u32PixelArrayFormat
                                                   faceInfo:&info
                                                    feature:&feature];

  if (result != MOK || feature.featureSize <= 0 || feature.feature == NULL) return nil;

  NSData *data = [NSData dataWithBytes:feature.feature length:(NSUInteger)feature.featureSize];
  return [data base64EncodedStringWithOptions:0];
}

- (float)compareFeature1:(NSData *)f1 feature2:(NSData *)f2 {
  if (!self.inited || !f1 || !f2) return 0.f;

  ASF_FaceFeature ff1 = {0};
  ff1.featureSize = (int)f1.length;
  ff1.feature = (MByte *)f1.bytes;

  ASF_FaceFeature ff2 = {0};
  ff2.featureSize = (int)f2.length;
  ff2.feature = (MByte *)f2.bytes;

  MFloat confidenceLevel = 0.0;
  [self.engine compareFaceWithFeature:&ff1 feature2:&ff2 confidenceLevel:&confidenceLevel];
  return confidenceLevel;
}

- (NSArray<NSNumber *> *)getAges {
  if (!self.inited) return @[];
  ASF_AgeInfo infos = {0};
  [self.engine getAge:&infos];

  NSMutableArray *arr = [NSMutableArray arrayWithCapacity:infos.num];
  for (int i = 0; i < infos.num; i++) {
    [arr addObject:@(infos.ageArray[i])];
  }
  return arr;
}

- (NSArray<NSNumber *> *)getGenders {
  if (!self.inited) return @[];
  ASF_GenderInfo infos = {0};
  [self.engine getGender:&infos];

  NSMutableArray *arr = [NSMutableArray arrayWithCapacity:infos.num];
  for (int i = 0; i < infos.num; i++) {
    // 0未知 1男 2女 (按 SDK 枚举可自行映射)
    [arr addObject:@(infos.genderArray[i])];
  }
  return arr;
}

- (NSArray<NSDictionary *> *)getFace3DAngles {
  return self.lastFace3DAngles ?: @[];
}

- (NSArray<NSNumber *> *)getLiveness {
  if (!self.inited) return @[];
  ASF_LivenessInfo infos = {0};
  [self.engine getLiveness:&infos];

  NSMutableArray *arr = [NSMutableArray arrayWithCapacity:infos.num];
  for (int i = 0; i < infos.num; i++) {
    [arr addObject:@(infos.isLive[i])];
  }
  return arr;
}

@end
