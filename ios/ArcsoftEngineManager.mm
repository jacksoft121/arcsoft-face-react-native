#import "ArcsoftEngineManager.h"

/// 逐行对照官方 iOS Demo：
/// - engine/ASFVideoProcessor.m
/// - engine/ASFImageProcessor.m
/// - util/Utility.m

@interface ArcsoftEngineManager ()
@property(nonatomic, readwrite) BOOL inited;
@property(nonatomic, strong, readwrite) ArcSoftFaceEngine *engine;
@end

@implementation ArcsoftEngineManager

- (instancetype)init {
  if (self = [super init]) {
    _engine = [[ArcSoftFaceEngine alloc] init];
    _inited = NO;
  }
  return self;
}

- (int)activateWithAppId:(NSString *)appId
                 sdkKey:(NSString *)sdkKey
              activeKey:(NSString *)activeKey {
  // 对照 Demo：通常在 App 启动时调用激活接口。
  // 不同 SDK 版本可能是 online/offline/activeKey 三种方式。
  // 这里采取“尽可能兼容”的调用：优先带 activeKey（如果框架提供），否则仅 appId+sdkKey。
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  if (activeKey.length > 0 && [self.engine respondsToSelector:@selector(activeWithAppId:sdkKey:activeKey:)]) {
    return (int)[self.engine performSelector:@selector(activeWithAppId:sdkKey:activeKey:)
                                  withObject:appId
                                  withObject:sdkKey
                                  withObject:activeKey];
  }
#pragma clang diagnostic pop

  // 绝大多数版本都有：activeOnlineWithAppId:sdkKey:
  if ([self.engine respondsToSelector:@selector(activeOnlineWithAppId:sdkKey:)]) {
    return [self.engine activeOnlineWithAppId:appId sdkKey:sdkKey];
  }

  // 若你的版本是离线激活，请在此处按官方 Demo 替换（比如 activeOffline:）
  return -1;
}

- (int)initEngineWithDetectMode:(ASF_DETECT_MODE)detectMode
                 orientPriority:(ASF_OP_0_ONLY)orientPriority
                     maxFaceNum:(int)maxFaceNum
                   combinedMask:(int)combinedMask {
  // 对照 Demo：initEngine
  int code = [self.engine initWithDetectMode:detectMode
                             orientPriority:orientPriority
                                      scale:16
                                 maxFaceNum:maxFaceNum
                               combinedMask:combinedMask];
  self.inited = (code == MOK);
  return code;
}

- (void)uninit {
  if (self.inited) {
    [self.engine unInit];
    self.inited = NO;
  }
}

- (NSArray<NSDictionary *> *)detectFaces:(ASVLOFFSCREEN *)offscreen {
  if (!self.inited || offscreen == NULL) return @[];

  NSArray<ArcSoftFaceInfo *> *faces = [self.engine detectFaces:offscreen];
  NSMutableArray *out = [NSMutableArray arrayWithCapacity:faces.count];
  for (ArcSoftFaceInfo *f in faces) {
    MRECT r = f.faceRect;
    [out addObject:@{
      @"rect": @{
        @"left": @(r.left),
        @"top": @(r.top),
        @"right": @(r.right),
        @"bottom": @(r.bottom),
      },
      @"orient": @(f.faceOrient),
    }];
  }
  return out;
}

- (NSString *)extractFeature:(ASVLOFFSCREEN *)offscreen
                    faceRect:(MRECT)rect
                      orient:(int)orient {
  if (!self.inited || offscreen == NULL) return nil;

  ArcSoftFaceInfo *info = [[ArcSoftFaceInfo alloc] init];
  info.faceRect = rect;
  info.faceOrient = orient;

  ArcSoftFaceFeature *feature = [self.engine extractFaceFeature:offscreen faceInfo:info];
  if (!feature || feature.featureSize <= 0 || feature.featureData == NULL) return nil;

  NSData *data = [NSData dataWithBytes:feature.featureData length:(NSUInteger)feature.featureSize];
  return [data base64EncodedStringWithOptions:0];
}

- (float)compareFeature1:(NSData *)f1 feature2:(NSData *)f2 {
  if (!self.inited || !f1 || !f2) return 0.f;

  ArcSoftFaceFeature *ff1 = [[ArcSoftFaceFeature alloc] init];
  ff1.featureSize = (int)f1.length;
  ff1.featureData = (MByte *)f1.bytes;

  ArcSoftFaceFeature *ff2 = [[ArcSoftFaceFeature alloc] init];
  ff2.featureSize = (int)f2.length;
  ff2.featureData = (MByte *)f2.bytes;

  return [self.engine compareFaceFeature:ff1 feature2:ff2];
}

- (NSArray<NSNumber *> *)getAges {
  if (!self.inited) return @[];
  NSArray<ArcSoftAgeInfo *> *infos = [self.engine getAge];
  NSMutableArray *arr = [NSMutableArray arrayWithCapacity:infos.count];
  for (ArcSoftAgeInfo *i in infos) {
    [arr addObject:@(i.age)];
  }
  return arr;
}

- (NSArray<NSNumber *> *)getGenders {
  if (!self.inited) return @[];
  NSArray<ArcSoftGenderInfo *> *infos = [self.engine getGender];
  NSMutableArray *arr = [NSMutableArray arrayWithCapacity:infos.count];
  for (ArcSoftGenderInfo *i in infos) {
    // 0未知 1男 2女 (按 SDK 枚举可自行映射)
    [arr addObject:@(i.gender)];
  }
  return arr;
}

- (NSArray<NSDictionary *> *)getFace3DAngles {
  if (!self.inited) return @[];
  NSArray<ArcSoftFace3DAngle *> *infos = [self.engine getFace3DAngle];
  NSMutableArray *arr = [NSMutableArray arrayWithCapacity:infos.count];
  for (ArcSoftFace3DAngle *a in infos) {
    [arr addObject:@{ @"yaw": @(a.yaw), @"pitch": @(a.pitch), @"roll": @(a.roll), @"status": @(a.status) }];
  }
  return arr;
}

- (NSArray<NSNumber *> *)getLiveness {
  if (!self.inited) return @[];
  NSArray<ArcSoftLivenessInfo *> *infos = [self.engine getLiveness];
  NSMutableArray *arr = [NSMutableArray arrayWithCapacity:infos.count];
  for (ArcSoftLivenessInfo *l in infos) {
    [arr addObject:@(l.liveness)];
  }
  return arr;
}

@end
