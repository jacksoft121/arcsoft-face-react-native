#import "ArcsoftFaceModule.h"
#import <React/RCTUtils.h>
#import <stdarg.h>

#ifndef RCT_NEW_ARCH_ENABLED
#import <React/RCTBridge.h>
#import <React/RCTBridgeModule.h>
#endif

#import "ArcsoftEngineManager.h"
#import "ArcsoftFaceDB.h"
#import "PixelBufferUtils.h"

@interface ArcsoftFaceModule ()
@property(nonatomic, strong) ArcsoftEngineManager *engineManager;
@property(nonatomic, strong) ArcsoftFaceDB *faceDB;
@end

@implementation ArcsoftFaceModule

RCT_EXPORT_MODULE(ArcsoftFace)

// =========================
// Logging
// =========================
static NSInteger ASF_LOG_LEVEL = 3;

static inline BOOL asf_log_enabled(NSInteger level) {
  return ASF_LOG_LEVEL != 0 && ASF_LOG_LEVEL >= level;
}

static inline void asf_logI(NSString *fmt, ...) {
  if (!asf_log_enabled(3)) return;
  va_list args; va_start(args, fmt);
  NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
  va_end(args);
  NSLog(@"[ArcsoftFaceRN][I] %@", msg);
}
static inline void asf_logD(NSString *fmt, ...) {
  if (!asf_log_enabled(4)) return;
  va_list args; va_start(args, fmt);
  NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
  va_end(args);
  NSLog(@"[ArcsoftFaceRN][D] %@", msg);
}
static inline void asf_logW(NSString *fmt, ...) {
  if (!asf_log_enabled(2)) return;
  va_list args; va_start(args, fmt);
  NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
  va_end(args);
  NSLog(@"[ArcsoftFaceRN][W] %@", msg);
}
static inline void asf_logE(NSError * _Nullable err, NSString *fmt, ...) {
  if (!asf_log_enabled(1)) return;
  va_list args; va_start(args, fmt);
  NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
  va_end(args);
  NSLog(@"[ArcsoftFaceRN][E] %@%@", msg, err ? [NSString stringWithFormat:@" | %@", err] : @"");
}

- (instancetype)init {
  if (self = [super init]) {
    _engineManager = [[ArcsoftEngineManager alloc] init];
    _faceDB = [[ArcsoftFaceDB alloc] init];
  }
  return self;
}

+ (BOOL)requiresMainQueueSetup {
  return NO;
}

#pragma mark - Helpers

static NSData * _Nullable DataFromBase64(NSString * _Nullable base64) {
  if (base64 == nil) return nil;
  return [[NSData alloc] initWithBase64EncodedString:base64 options:0];
}

static ASVLOFFSCREEN OffscreenFromData(NSData *data, int width, int height, NSString *formatStr) {
    ASVLOFFSCREEN offscreen = {0};
    offscreen.i32Width = width;
    offscreen.i32Height = height;

    if ([formatStr isEqualToString:@"NV21"]) {
        offscreen.u32PixelArrayFormat = ASVL_PAF_NV21;
        offscreen.pi32Pitch[0] = width;
        offscreen.pi32Pitch[1] = width;
        MUInt8 *bytes = (MUInt8 *)data.bytes;
        offscreen.ppu8Plane[0] = bytes;
        offscreen.ppu8Plane[1] = bytes + (width * height);
    } else if ([formatStr isEqualToString:@"NV12"]) {
        offscreen.u32PixelArrayFormat = ASVL_PAF_NV12;
        offscreen.pi32Pitch[0] = width;
        offscreen.pi32Pitch[1] = width;
        MUInt8 *bytes = (MUInt8 *)data.bytes;
        offscreen.ppu8Plane[0] = bytes;
        offscreen.ppu8Plane[1] = bytes + (width * height);
    } else if ([formatStr isEqualToString:@"RGB"]) {
        offscreen.u32PixelArrayFormat = ASVL_PAF_RGB24_B8G8R8;
        offscreen.pi32Pitch[0] = width * 3;
        offscreen.ppu8Plane[0] = (MUInt8 *)data.bytes;
    } else {
        offscreen.u32PixelArrayFormat = ASVL_PAF_NV21;
        offscreen.pi32Pitch[0] = width;
        offscreen.pi32Pitch[1] = width;
        MUInt8 *bytes = (MUInt8 *)data.bytes;
        offscreen.ppu8Plane[0] = bytes;
        offscreen.ppu8Plane[1] = bytes + (width * height);
    }
    return offscreen;
}

#pragma mark - NativeArcsoftFaceSpec Implementation

// 直接实现协议方法，不使用 RCT_EXPORT_METHOD

- (void)setLogLevel:(double)level
            resolve:(RCTPromiseResolveBlock)resolve
             reject:(RCTPromiseRejectBlock)reject
{
  @try {
    ASF_LOG_LEVEL = (NSInteger)level;
    asf_logI(@"setLogLevel=%ld", (long)ASF_LOG_LEVEL);
    resolve(@(YES));
  } @catch (NSException *e) {
    reject(@"SET_LOG_LEVEL_FAILED", e.reason, nil);
  }
}

- (void)activateOnline:(NSString *)appId
                sdkKey:(NSString *)sdkKey
               resolve:(RCTPromiseResolveBlock)resolve
                reject:(RCTPromiseRejectBlock)reject
{
  long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  asf_logI(@"activateOnline(appId.len=%lu, sdkKey.len=%lu)", (unsigned long)appId.length, (unsigned long)sdkKey.length);

  int code = [self.engineManager activateWithAppId:appId sdkKey:sdkKey activeKey:nil];
  long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;
  asf_logI(@"activateOnline => code=%d, cost=%lldms", code, cost);

  if (code == MOK || code == MERR_ASF_ALREADY_ACTIVATED) {
    resolve(@(code));
  } else {
    asf_logE(nil, @"activateOnline failed: %d", code);
    reject(@"ACTIVATE_FAILED", [NSString stringWithFormat:@"ArcSoft iOS activateOnline failed: %d", code], nil);
  }
}

- (void)initEngine:(NSDictionary *)options
           resolve:(RCTPromiseResolveBlock)resolve
            reject:(RCTPromiseRejectBlock)reject
{
  @try {
      long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
      asf_logI(@"initEngine start");

      // Default values
      ASF_DetectMode detectMode = ASF_DETECT_MODE_IMAGE;
      ASF_OrientPriority orientPriority = ASF_OP_0_ONLY;
      int maxFaceNum = 1;
      int combinedMask = ASF_FACE_DETECT | ASF_FACERECOGNITION; // Default mask

      // Safe parsing
      if (options && [options isKindOfClass:[NSDictionary class]]) {
          asf_logI(@"initEngine parsing options");

          // detectMode
          NSObject *mode = [options objectForKey:@"detectMode"];
          if (mode && [mode isKindOfClass:[NSString class]]) {
              if ([(NSString *)mode isEqualToString:@"video"]) {
                  detectMode = ASF_DETECT_MODE_VIDEO;
              }
          }

          // orientPriority
          NSObject *orient = [options objectForKey:@"orientPriority"];
          if (orient && [orient respondsToSelector:@selector(unsignedIntValue)]) {
              orientPriority = (ASF_OrientPriority)[(NSNumber *)orient unsignedIntValue];
          }

          // maxFaceNum
          NSObject *maxNum = [options objectForKey:@"maxFaceNum"];
          if (maxNum && [maxNum respondsToSelector:@selector(intValue)]) {
              maxFaceNum = [(NSNumber *)maxNum intValue];
          }

          // Flags
          NSObject *enableAge = [options objectForKey:@"enableAge"];
          if (enableAge && [enableAge respondsToSelector:@selector(boolValue)] && [(NSNumber *)enableAge boolValue]) combinedMask |= ASF_AGE;

          NSObject *enableGender = [options objectForKey:@"enableGender"];
          if (enableGender && [enableGender respondsToSelector:@selector(boolValue)] && [(NSNumber *)enableGender boolValue]) combinedMask |= ASF_GENDER;

          NSObject *enableLiveness = [options objectForKey:@"enableLiveness"];
          if (enableLiveness && [enableLiveness respondsToSelector:@selector(boolValue)] && [(NSNumber *)enableLiveness boolValue]) combinedMask |= ASF_LIVENESS;
      }

      asf_logI(@"initEngine calling manager");
      int code = [self.engineManager initEngineWithDetectMode:detectMode
                                               orientPriority:orientPriority
                                                   maxFaceNum:maxFaceNum
                                                 combinedMask:combinedMask];

      long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;
      asf_logI(@"initEngine => code=%d, mask=%d, cost=%lldms", code, combinedMask, cost);

      if (code == MOK) {
        resolve(@(code));
      } else {
        asf_logE(nil, @"initEngine failed: %d", code);
        reject(@"INIT_FAILED", [NSString stringWithFormat:@"ArcSoft iOS initEngine failed: %d", code], nil);
      }
  } @catch (NSException *e) {
      asf_logE(nil, @"initEngine exception: %@", e.reason);
      reject(@"INIT_EXCEPTION", e.reason, nil);
  }
}

- (void)unInitEngine:(RCTPromiseResolveBlock)resolve
              reject:(RCTPromiseRejectBlock)reject
{
  long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  asf_logI(@"unInitEngine()");

  [self.engineManager uninit];

  long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;
  asf_logI(@"unInitEngine => ok, cost=%lldms", cost);
  resolve(@(0));
}

- (void)detectFacesNV21:(NSArray *)nv21
                  width:(double)width
                 height:(double)height
                resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject
{
  long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  asf_logD(@"detectFaces(image.len=%lu)", (unsigned long)nv21.count);

  // 性能警告：在 ObjC 中遍历 NSArray 转 byte[] 非常慢！
  // 强烈建议 JS 端改传 base64 string。

  id dataObj = nv21;
  NSData *data = nil;
  if ([dataObj isKindOfClass:[NSString class]]) {
      data = [[NSData alloc] initWithBase64EncodedString:dataObj options:0];
  } else if ([dataObj isKindOfClass:[NSArray class]]) {
      NSMutableData *md = [NSMutableData dataWithCapacity:[dataObj count]];
      for (NSNumber *n in dataObj) {
          uint8_t b = [n unsignedCharValue];
          [md appendBytes:&b length:1];
      }
      data = md;
  }

  if (!data) {
    reject(@"BAD_DATA", @"nv21 data is invalid", nil);
    return;
  }

  ASVLOFFSCREEN offscreen = OffscreenFromData(data, (int)width, (int)height, @"NV21");

  NSArray<NSDictionary *> *faces = [self.engineManager detectFaces:&offscreen];

  long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;
  asf_logD(@"detectFaces => faces=%lu, cost=%lldms", (unsigned long)faces.count, cost);

  resolve(faces);
}

- (void)extractFeatureNV21:(NSArray *)nv21
                     width:(double)width
                    height:(double)height
                      face:(NSDictionary *)face
                   resolve:(RCTPromiseResolveBlock)resolve
                    reject:(RCTPromiseRejectBlock)reject
{
  long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  asf_logD(@"extractFeature(faceIndex=%@)", face);

  id dataObj = nv21;
  NSData *data = nil;
  if ([dataObj isKindOfClass:[NSString class]]) {
      data = [[NSData alloc] initWithBase64EncodedString:dataObj options:0];
  } else if ([dataObj isKindOfClass:[NSArray class]]) {
      NSMutableData *md = [NSMutableData dataWithCapacity:[dataObj count]];
      for (NSNumber *n in dataObj) {
          uint8_t b = [n unsignedCharValue];
          [md appendBytes:&b length:1];
      }
      data = md;
  }

  if (!data) {
    reject(@"BAD_DATA", @"nv21 data is invalid", nil);
    return;
  }

  ASVLOFFSCREEN offscreen = OffscreenFromData(data, (int)width, (int)height, @"NV21");

  NSDictionary *rectDict = face[@"rect"];
  MRECT rect = {
      [rectDict[@"left"] intValue],
      [rectDict[@"top"] intValue],
      [rectDict[@"right"] intValue],
      [rectDict[@"bottom"] intValue]
  };
  int orient = [face[@"orient"] intValue];

  NSString *featBase64 = [self.engineManager extractFeature:&offscreen faceRect:rect orient:orient];

  long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;

  if (!featBase64) {
    asf_logW(@"extractFeature => null (extraction failed)");
    resolve([NSNull null]);
    return;
  }

  asf_logD(@"extractFeature => ok, cost=%lldms", cost);
  resolve(@{ @"dataBase64": featBase64 });
}

- (void)compareFeature:(NSDictionary *)f1
                    f2:(NSDictionary *)f2
               resolve:(RCTPromiseResolveBlock)resolve
                reject:(RCTPromiseRejectBlock)reject
{
  long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  asf_logD(@"compareFeature()");

  NSData *d1 = DataFromBase64(f1[@"dataBase64"]);
  NSData *d2 = DataFromBase64(f2[@"dataBase64"]);
  if (!d1 || !d2) {
    asf_logE(nil, @"compareFeature failed: bad feature");
    reject(@"BAD_FEATURE", @"f1.dataBase64 and f2.dataBase64 are required", nil);
    return;
  }

  float score = [self.engineManager compareFeature1:d1 feature2:d2];

  long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;
  asf_logD(@"compareFeature => score=%f, cost=%lldms", score, cost);

  resolve(@(score));
}

- (void)getAgeNV21:(NSArray *)nv21
             width:(double)width
            height:(double)height
             faces:(NSArray *)faces
           resolve:(RCTPromiseResolveBlock)resolve
            reject:(RCTPromiseRejectBlock)reject
{
    // 简化实现：直接调用 Manager 的 getAges (假设 detectFaces 已经运行过)
    // 注意：这依赖于 detectFaces 已经更新了 Manager 的内部状态
    // 如果是新的图像数据，应该先 detect
    // 但为了性能，通常是在 detectFaces 后立即调用，所以 Manager 状态应该是新的
    resolve([self.engineManager getAges]);
}

- (void)getGenderNV21:(NSArray *)nv21
                width:(double)width
               height:(double)height
                faces:(NSArray *)faces
              resolve:(RCTPromiseResolveBlock)resolve
               reject:(RCTPromiseRejectBlock)reject
{
    resolve([self.engineManager getGenders]);
}

- (void)getLivenessNV21:(NSArray *)nv21
                  width:(double)width
                 height:(double)height
                  faces:(NSArray *)faces
                resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject
{
    resolve([self.engineManager getLiveness]);
}

- (void)getFace3DAngleNV21:(NSArray *)nv21
                     width:(double)width
                    height:(double)height
                     faces:(NSArray *)faces
                   resolve:(RCTPromiseResolveBlock)resolve
                    reject:(RCTPromiseRejectBlock)reject
{
    resolve([self.engineManager getFace3DAngles]);
}

- (void)faceDBAdd:(NSString *)userId
          feature:(NSDictionary *)feature
          resolve:(RCTPromiseResolveBlock)resolve
           reject:(RCTPromiseRejectBlock)reject
{
  long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  asf_logI(@"faceDBAdd(userId=%@)", userId);

  NSData *d = DataFromBase64(feature[@"dataBase64"]);
  if (!d) {
    asf_logE(nil, @"faceDBAdd failed: bad feature");
    reject(@"BAD_FEATURE", @"feature.dataBase64 required", nil);
    return;
  }

  BOOL success = [self.faceDB upsertFeatureData:d forUserId:userId withEngine:self.engineManager.engine];

  long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;
  asf_logD(@"faceDBAdd => ok=%d, cost=%lldms", success, cost);

  resolve(@(success));
}

- (void)faceDBRemove:(NSString *)userId
             resolve:(RCTPromiseResolveBlock)resolve
              reject:(RCTPromiseRejectBlock)reject
{
  long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  asf_logI(@"faceDBRemove(userId=%@)", userId);

  BOOL success = [self.faceDB removeFeatureForUserId:userId withEngine:self.engineManager.engine];

  long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;
  asf_logD(@"faceDBRemove => ok=%d, cost=%lldms", success, cost);

  resolve(@(success));
}

- (void)faceDBSearch:(NSDictionary *)feature
           threshold:(double)threshold
             resolve:(RCTPromiseResolveBlock)resolve
              reject:(RCTPromiseRejectBlock)reject
{
  long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  asf_logD(@"faceDBSearch(threshold=%f)", threshold);

  NSData *d = DataFromBase64(feature[@"dataBase64"]);
  if (!d) {
    asf_logE(nil, @"faceDBSearch failed: bad feature");
    reject(@"BAD_FEATURE", @"feature.dataBase64 required", nil);
    return;
  }

  NSDictionary *result = [self.faceDB searchWithEngine:self.engineManager.engine featureData:d threshold:(float)threshold];

  long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;

  if (result) {
      asf_logD(@"faceDBSearch => id=%@, score=%@, cost=%lldms", result[@"id"], result[@"score"], cost);
      resolve(result);
  } else {
      asf_logD(@"faceDBSearch => null, cost=%lldms", cost);
      resolve(@{ @"id": [NSNull null], @"score": @(0) });
  }
}

- (void)faceDBClear:(RCTPromiseResolveBlock)resolve
             reject:(RCTPromiseRejectBlock)reject
{
  long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  asf_logI(@"faceDBClear()");

  BOOL success = [self.faceDB clearWithEngine:self.engineManager.engine];

  long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;
  asf_logD(@"faceDBClear => ok=%d, cost=%lldms", success, cost);

  resolve(@(success));
}

- (void)faceDBCount:(RCTPromiseResolveBlock)resolve
             reject:(RCTPromiseRejectBlock)reject
{
  long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  asf_logD(@"faceDBCount()");

  NSInteger count = [self.faceDB countWithEngine:self.engineManager.engine];

  long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;
  asf_logD(@"faceDBCount => %ld, cost=%lldms", (long)count, cost);

  resolve(@(count));
}

#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeArcsoftFaceSpecJSI>(params);
}
#endif

@end
