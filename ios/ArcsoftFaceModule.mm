#import "ArcsoftFaceModule.h"
#import <React/RCTUtils.h>
#import <stdarg.h>

#import "ArcsoftEngineManager.h"
#import "PixelBufferUtils.h"

@interface ArcsoftFaceModule ()
@property(nonatomic, strong) ArcsoftEngineManager *engineManager;
@end

@implementation ArcsoftFaceModule

RCT_EXPORT_MODULE(ArcsoftFace)

// =========================
// Logging (日志工具)
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
    @try {
        _engineManager = [ArcsoftEngineManager sharedInstance]; // 使用单例
        NSLog(@"[ArcsoftFaceRN] Module initialized successfully");
    } @catch (NSException *exception) {
        NSLog(@"[ArcsoftFaceRN] Module initialization failed: %@", exception);
    }
  }
  return self;
}

+ (BOOL)requiresMainQueueSetup {
  return NO;
}

#pragma mark - Helpers (辅助方法)

// Base64 字符串转 NSData
static NSData * _Nullable DataFromBase64(NSString * _Nullable base64) {
  if (base64 == nil) return nil;
  return [[NSData alloc] initWithBase64EncodedString:base64 options:0];
}

// Base64 字符串转 UIImage
static UIImage * _Nullable ImageFromBase64(NSString * _Nullable base64) {
    NSData *data = DataFromBase64(base64);
    if (!data) return nil;
    return [UIImage imageWithData:data];
}

// 将 NSData (NV21/RGB) 转换为 ArcSoft 的 ASVLOFFSCREEN 结构体
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
        // 默认 NV21
        offscreen.u32PixelArrayFormat = ASVL_PAF_NV21;
        offscreen.pi32Pitch[0] = width;
        offscreen.pi32Pitch[1] = width;
        MUInt8 *bytes = (MUInt8 *)data.bytes;
        offscreen.ppu8Plane[0] = bytes;
        offscreen.ppu8Plane[1] = bytes + (width * height);
    }
    return offscreen;
}

#pragma mark - Exported Methods (导出给 JS 的方法)

/**
 * 设置日志级别
 */
RCT_EXPORT_METHOD(setLogLevel:(double)level
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  @try {
    ASF_LOG_LEVEL = (NSInteger)level;
    asf_logI(@"setLogLevel=%ld", (long)ASF_LOG_LEVEL);
    resolve(@(YES));
  } @catch (NSException *e) {
    reject(@"SET_LOG_LEVEL_FAILED", e.reason, nil);
  }
}

/**
 * 在线激活 SDK
 */
RCT_EXPORT_METHOD(activateOnline:(NSString *)appId
                  sdkKey:(NSString *)sdkKey
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
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

/**
 * 获取激活文件信息
 */
RCT_EXPORT_METHOD(getActiveFileInfo:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
    asf_logD(@"getActiveFileInfo()");

    NSDictionary *info = [self.engineManager getActiveFileInfo];
    long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;

    if (info) {
        asf_logD(@"getActiveFileInfo => ok, cost=%lldms", cost);
        resolve(info);
    } else {
        asf_logW(@"getActiveFileInfo => null");
        resolve([NSNull null]);
    }
}

/**
 * 初始化引擎
 */
RCT_EXPORT_METHOD(initEngine:(NSDictionary *)options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  @try {
      long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
      asf_logI(@"initEngine start");

      // 默认值
      ASF_DetectMode detectMode = ASF_DETECT_MODE_IMAGE;
      ASF_OrientPriority orientPriority = ASF_OP_0_ONLY;
      int maxFaceNum = 1;
      int combinedMask = ASF_FACE_DETECT | ASF_FACERECOGNITION; // 默认开启检测和识别

      // 解析参数
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

          // 功能开关
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

/**
 * 销毁引擎
 */
RCT_EXPORT_METHOD(unInitEngine:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  asf_logI(@"unInitEngine()");

  [self.engineManager uninit];

  long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;
  asf_logI(@"unInitEngine => ok, cost=%lldms", cost);
  resolve(@(0));
}

/**
 * NV21 人脸检测
 */
RCT_EXPORT_METHOD(detectFacesNV21:(NSArray *)nv21
                  width:(double)width
                  height:(double)height
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  asf_logD(@"detectFaces(image.len=%lu)", (unsigned long)nv21.count);

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

/**
 * NV21 特征提取
 */
RCT_EXPORT_METHOD(extractFeatureNV21:(NSArray *)nv21
                  width:(double)width
                  height:(double)height
                  face:(NSDictionary *)face
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
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

  // 修复：传入 nil 作为 faceDataInfo
  NSString *featBase64 = [self.engineManager extractFeature:&offscreen faceRect:rect orient:orient faceDataInfo:nil];

  long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;

  if (!featBase64) {
    asf_logW(@"extractFeature => null (extraction failed)");
    resolve([NSNull null]);
    return;
  }

  asf_logD(@"extractFeature => ok, cost=%lldms", cost);
  resolve(@{ @"dataBase64": featBase64 });
}

RCT_EXPORT_METHOD(getAgeNV21:(NSArray *)nv21
                  width:(double)width
                  height:(double)height
                  faces:(NSArray *)faces
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    resolve([self.engineManager getAges]);
}

RCT_EXPORT_METHOD(getGenderNV21:(NSArray *)nv21
                  width:(double)width
                  height:(double)height
                  faces:(NSArray *)faces
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    resolve([self.engineManager getGenders]);
}

RCT_EXPORT_METHOD(getLivenessNV21:(NSArray *)nv21
                  width:(double)width
                  height:(double)height
                  faces:(NSArray *)faces
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    resolve([self.engineManager getLiveness]);
}

RCT_EXPORT_METHOD(getFace3DAngleNV21:(NSArray *)nv21
                  width:(double)width
                  height:(double)height
                  faces:(NSArray *)faces
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    resolve([self.engineManager getFace3DAngles]);
}

// =========================
// Image (Base64)
// =========================

/**
 * Base64 图片人脸检测
 */
RCT_EXPORT_METHOD(detectFacesImage:(NSString *)base64
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
    asf_logD(@"detectFacesImage(len=%lu)", (unsigned long)base64.length);

    UIImage *image = ImageFromBase64(base64);
    if (!image) {
        reject(@"BAD_IMAGE", @"Invalid base64 image", nil);
        return;
    }

    NSArray<NSDictionary *> *faces = [self.engineManager detectFacesFromImage:image];

    long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;
    asf_logD(@"detectFacesImage => faces=%lu, cost=%lldms", (unsigned long)faces.count, cost);

    // 移除 faceDataInfo，避免传回 JS
    NSMutableArray *cleanFaces = [NSMutableArray arrayWithCapacity:faces.count];
    for (NSDictionary *face in faces) {
        NSMutableDictionary *mFace = [face mutableCopy];
        [mFace removeObjectForKey:@"faceDataInfo"];
        [cleanFaces addObject:mFace];
    }

    resolve(cleanFaces);
}

/**
 * Base64 图片特征提取
 */
RCT_EXPORT_METHOD(extractFeatureImage:(NSString *)base64
                  face:(NSDictionary *)face
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
    asf_logD(@"extractFeatureImage()");

    UIImage *image = ImageFromBase64(base64);
    if (!image) {
        reject(@"BAD_IMAGE", @"Invalid base64 image", nil);
        return;
    }

    NSMutableDictionary *mutableFace = [face mutableCopy];
    id faceDataInfoObj = mutableFace[@"faceDataInfo"];

    // 如果 faceDataInfo 缺失，重新检测以获取完整信息
    if (!faceDataInfoObj) {
        asf_logD(@"extractFeatureImage: faceDataInfo missing, re-detecting faces...");
        NSArray<NSDictionary *> *faces = [self.engineManager detectFacesFromImage:image];
        if (faces.count > 0) {
            // 使用重新检测到的第一个人脸信息 (包含 faceDataInfo)
            // 注意：这里简单取第一个，如果需要更精确，可以比较 rect
            mutableFace = [faces[0] mutableCopy];
            asf_logD(@"extractFeatureImage: re-detected face found");
        } else {
            asf_logW(@"extractFeatureImage: re-detection failed (no faces)");
            resolve([NSNull null]);
            return;
        }
    } else if ([faceDataInfoObj isKindOfClass:[NSString class]]) {
        // 如果传回来的是 Base64 字符串 (虽然我们目前没传)，转回 NSData
        NSData *data = [[NSData alloc] initWithBase64EncodedString:faceDataInfoObj options:0];
        mutableFace[@"faceDataInfo"] = data;
    }

    NSString *featBase64 = [self.engineManager extractFeatureFromImage:image faceInfo:mutableFace];

    long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;

    if (!featBase64) {
        asf_logW(@"extractFeatureImage => null");
        resolve([NSNull null]);
        return;
    }

    asf_logD(@"extractFeatureImage => ok, cost=%lldms", cost);
    resolve(@{ @"dataBase64": featBase64 });
}

RCT_EXPORT_METHOD(getAgeImage:(NSString *)base64
                  faces:(NSArray *)faces
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    UIImage *image = ImageFromBase64(base64);
    if (image) {
        [self.engineManager detectFacesFromImage:image];
    }
    resolve([self.engineManager getAges]);
}

RCT_EXPORT_METHOD(getGenderImage:(NSString *)base64
                  faces:(NSArray *)faces
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    UIImage *image = ImageFromBase64(base64);
    if (image) {
        [self.engineManager detectFacesFromImage:image];
    }
    resolve([self.engineManager getGenders]);
}

RCT_EXPORT_METHOD(getLivenessImage:(NSString *)base64
                  faces:(NSArray *)faces
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    UIImage *image = ImageFromBase64(base64);
    if (image) {
        [self.engineManager detectFacesFromImage:image];
    }
    resolve([self.engineManager getLiveness]);
}

RCT_EXPORT_METHOD(getFace3DAngleImage:(NSString *)base64
                  faces:(NSArray *)faces
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    UIImage *image = ImageFromBase64(base64);
    if (image) {
        [self.engineManager detectFacesFromImage:image];
    }
    resolve([self.engineManager getFace3DAngles]);
}

/**
 * 特征比对 (1:1)
 */
RCT_EXPORT_METHOD(compareFeature:(NSDictionary *)f1
                  f2:(NSDictionary *)f2
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
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

/**
 * 注册人脸特征
 */
RCT_EXPORT_METHOD(registerFaceFeature:(NSString *)userId
                  feature:(NSDictionary *)feature
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  asf_logI(@"registerFaceFeature(userId=%@)", userId);

  NSData *d = DataFromBase64(feature[@"dataBase64"]);
  if (!d) {
    asf_logE(nil, @"registerFaceFeature failed: bad feature");
    reject(@"BAD_FEATURE", @"feature.dataBase64 required", nil);
    return;
  }

  BOOL success = [self.engineManager faceDBAddOrUpdate:userId featureData:d];

  long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;
  asf_logD(@"registerFaceFeature => ok=%d, cost=%lldms", success, cost);

  resolve(@(success));
}

/**
 * 移除人脸特征
 */
RCT_EXPORT_METHOD(removeFaceFeature:(NSString *)userId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  asf_logI(@"removeFaceFeature(userId=%@)", userId);

  BOOL success = [self.engineManager faceDBRemove:userId];

  long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;
  asf_logD(@"removeFaceFeature => ok=%d, cost=%lldms", success, cost);

  resolve(@(success));
}

/**
 * 搜索人脸 (1:N)
 */
RCT_EXPORT_METHOD(searchFaceFeature:(NSDictionary *)feature
                  threshold:(double)threshold
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  asf_logD(@"searchFaceFeature(threshold=%f)", threshold);

  NSData *d = DataFromBase64(feature[@"dataBase64"]);
  if (!d) {
    asf_logE(nil, @"searchFaceFeature failed: bad feature");
    reject(@"BAD_FEATURE", @"feature.dataBase64 required", nil);
    return;
  }

  NSDictionary *result = [self.engineManager faceDBSearchTop1:d threshold:(float)threshold];

  long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;

  if (result) {
      asf_logD(@"searchFaceFeature => id=%@, score=%@, cost=%lldms", result[@"id"], result[@"score"], cost);
      resolve(result);
  } else {
      asf_logD(@"searchFaceFeature => null, cost=%lldms", cost);
      resolve(@{ @"id": [NSNull null], @"score": @(0) });
  }
}

/**
 * 清空人脸库
 */
RCT_EXPORT_METHOD(clearAllFaceFeature:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  asf_logI(@"clearAllFaceFeature()");

  BOOL success = [self.engineManager faceDBClear];

  long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;
  asf_logD(@"clearAllFaceFeature => ok=%d, cost=%lldms", success, cost);

  resolve(@(success));
}

/**
 * 获取人脸库数量
 */
RCT_EXPORT_METHOD(getFaceCount:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  long long t0 = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  asf_logD(@"getFaceCount()");

  NSInteger count = [self.engineManager faceDBCount];

  long long cost = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) - t0;
  asf_logD(@"getFaceCount => %ld, cost=%lldms", (long)count, cost);

  resolve(@(count));
}

@end
