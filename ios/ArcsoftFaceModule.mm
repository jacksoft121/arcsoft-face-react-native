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

/// 注意：不打包 ArcSoftFaceEngine.framework，本插件只引用其头文件。
/// 你需要在 App 工程里按官方文档把 ArcSoftFaceEngine.framework 加入：
/// - iOS Demo 对照：ArcSoftFaceEngineDemo.xcodeproj 的 Frameworks 配置。

@interface ArcsoftFaceModule ()
@property(nonatomic, strong) ArcsoftEngineManager *engineManager;
@property(nonatomic, strong) ArcsoftFaceDB *faceDB;
@end

@implementation ArcsoftFaceModule

// =========================
// Logging
// 0=OFF 1=ERROR 2=WARN 3=INFO 4=DEBUG 5=VERBOSE
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

#pragma mark - Logging

RCT_EXPORT_METHOD(setLogLevel:(nonnull NSNumber *)level
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  @try {
    ASF_LOG_LEVEL = [level integerValue];
    asf_logI(@"setLogLevel=%ld", (long)ASF_LOG_LEVEL);
    resolve(level);
  } @catch (NSException *e) {
    reject(@"SET_LOG_LEVEL_FAILED", e.reason, nil);
  }
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

// Helper to create ASVLOFFSCREEN from raw bytes
static ASVLOFFSCREEN OffscreenFromData(NSData *data, int width, int height, NSString *formatStr) {
    ASVLOFFSCREEN offscreen = {0};
    offscreen.i32Width = width;
    offscreen.i32Height = height;

    // Default to NV21 if not specified or unknown
    // Note: iOS usually uses NV12 or BGRA. Android uses NV21.
    // If data comes from JS, it might be raw bytes.
    // We need to map format string to ASVL format.

    if ([formatStr isEqualToString:@"NV21"]) {
        offscreen.u32PixelArrayFormat = ASVL_PAF_NV21;
        offscreen.pi32Pitch[0] = width;
        offscreen.pi32Pitch[1] = width;

        // NV21: Y plane + VU plane
        // Y size = w * h
        // VU size = w * h / 2

        // We need to be careful about memory management here.
        // The data.bytes pointer is valid as long as data is valid.
        // Since we use it synchronously in the method call, it should be fine.
        // However, ASVLOFFSCREEN expects mutable pointers (MUInt8*), but NSData.bytes is const void*.
        // We cast it, but we must ensure we don't modify it if it's immutable data.
        // ArcSoft engine usually only reads for detection.

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
        // Assuming RGB24
        offscreen.u32PixelArrayFormat = ASVL_PAF_RGB24_B8G8R8; // Check endianness/order
        offscreen.pi32Pitch[0] = width * 3;
        offscreen.ppu8Plane[0] = (MUInt8 *)data.bytes;
    } else {
        // Fallback or error
        offscreen.u32PixelArrayFormat = ASVL_PAF_NV21;
        offscreen.pi32Pitch[0] = width;
        offscreen.pi32Pitch[1] = width;
        MUInt8 *bytes = (MUInt8 *)data.bytes;
        offscreen.ppu8Plane[0] = bytes;
        offscreen.ppu8Plane[1] = bytes + (width * height);
    }

    return offscreen;
}


#pragma mark - Public API (aligned with TS spec)

RCT_EXPORT_METHOD(activateOnline:(NSString *)appId
                  sdkKey:(NSString *)sdkKey
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  asf_logI(@"activateOnline appIdLen=%lu", (unsigned long)appId.length);

  int code = [self.engineManager activateWithAppId:appId sdkKey:sdkKey activeKey:nil];
  if (code == MOK || code == MERR_ASF_ALREADY_ACTIVATED) {
    resolve(@(YES));
  } else {
    reject(@"ACTIVATE_FAILED", [NSString stringWithFormat:@"ArcSoft iOS activateOnline failed: %d", code], nil);
  }
}

RCT_EXPORT_METHOD(initEngine:(NSDictionary *)options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  asf_logI(@"initEngine options=%@", options);

  // Default values
  ASF_DetectMode detectMode = ASF_DETECT_MODE_IMAGE;
  ASF_OrientPriority orientPriority = ASF_OP_0_ONLY;
  int maxFaceNum = 1;
  int combinedMask = ASF_FACE_DETECT;

  if (options[@"detectMode"]) {
      // Map string/number to enum
      // Assuming TS passes integer or we map string
      // For simplicity, assuming integer passed from JS matching constants
      detectMode = (ASF_DetectMode)[options[@"detectMode"] unsignedIntValue];
  }

  if (options[@"orientPriority"]) {
      orientPriority = (ASF_OrientPriority)[options[@"orientPriority"] unsignedIntValue];
  }

  if (options[@"maxFaceNum"]) {
      maxFaceNum = [options[@"maxFaceNum"] intValue];
  }

  if (options[@"combinedMask"]) {
      combinedMask = [options[@"combinedMask"] intValue];
  }

  int code = [self.engineManager initEngineWithDetectMode:detectMode
                                           orientPriority:orientPriority
                                               maxFaceNum:maxFaceNum
                                             combinedMask:combinedMask];

  if (code == MOK) {
    resolve(@(YES));
  } else {
    reject(@"INIT_FAILED", [NSString stringWithFormat:@"ArcSoft iOS initEngine failed: %d", code], nil);
  }
}

RCT_EXPORT_METHOD(unInitEngine:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  asf_logI(@"unInitEngine");

  [self.engineManager uninit];
  resolve(@(YES));
}

RCT_EXPORT_METHOD(detectFaces:(NSDictionary *)image
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  asf_logD(@"detectFaces image=%@", image);

  NSData *data = DataFromBase64(image[@"data"]);
  if (!data) {
    reject(@"BAD_IMAGE", @"image.data (base64) is required", nil);
    return;
  }

  int width = [image[@"width"] intValue];
  int height = [image[@"height"] intValue];
  NSString *formatStr = image[@"format"] ?: @"NV21";

  ASVLOFFSCREEN offscreen = OffscreenFromData(data, width, height, formatStr);

  NSArray<NSDictionary *> *faces = [self.engineManager detectFaces:&offscreen];
  resolve(@{ @"faces": faces });
}

RCT_EXPORT_METHOD(extractFeature:(NSDictionary *)image
                  faceIndex:(double)faceIndex
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  asf_logD(@"extractFeature faceIndex=%f", faceIndex);

  NSData *data = DataFromBase64(image[@"data"]);
  if (!data) {
    reject(@"BAD_IMAGE", @"image.data (base64) is required", nil);
    return;
  }
  int width = [image[@"width"] intValue];
  int height = [image[@"height"] intValue];
  NSString *formatStr = image[@"format"] ?: @"NV21";

  // We need to detect faces first to get the rect and orient for the specific face index
  // Or we assume the caller passed the rect/orient?
  // The TS spec usually implies we might need to detect or pass rect.
  // If the API signature is just image + faceIndex, we must detect first.

  ASVLOFFSCREEN offscreen = OffscreenFromData(data, width, height, formatStr);
  NSArray<NSDictionary *> *faces = [self.engineManager detectFaces:&offscreen];

  if (faceIndex < 0 || faceIndex >= faces.count) {
      resolve([NSNull null]);
      return;
  }

  NSDictionary *face = faces[(NSUInteger)faceIndex];
  NSDictionary *rectDict = face[@"rect"];
  MRECT rect = {
      [rectDict[@"left"] intValue],
      [rectDict[@"top"] intValue],
      [rectDict[@"right"] intValue],
      [rectDict[@"bottom"] intValue]
  };
  int orient = [face[@"orient"] intValue];

  NSString *featBase64 = [self.engineManager extractFeature:&offscreen faceRect:rect orient:orient];

  if (!featBase64) {
    resolve([NSNull null]);
    return;
  }
  resolve(@{ @"dataBase64": featBase64 });
}

RCT_EXPORT_METHOD(compareFeature:(NSDictionary *)f1
                  f2:(NSDictionary *)f2
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  asf_logD(@"compareFeature");

  NSData *d1 = DataFromBase64(f1[@"dataBase64"]);
  NSData *d2 = DataFromBase64(f2[@"dataBase64"]);
  if (!d1 || !d2) {
    reject(@"BAD_FEATURE", @"f1.dataBase64 and f2.dataBase64 are required", nil);
    return;
  }

  float score = [self.engineManager compareFeature1:d1 feature2:d2];
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
    // This method is a bit complex because process() in ArcSoft usually processes all detected faces
    // and stores results in the engine. Then we call getAge, getGender etc.
    // The detectFaces call in this module already calls process() if combinedMask has these bits.
    // If the user calls this method, they might expect us to run process() again or just return cached values.
    // However, since detectFaces updates the cache (in our implementation of ArcsoftEngineManager),
    // we can just return the values if they are available.
    // BUT, if this is a separate call with a new image, we must detect and process again.

    // Assuming this call provides an image, we should run detection and processing.

    NSData *data = DataFromBase64(image[@"data"]);
    if (!data) {
      reject(@"BAD_IMAGE", @"image.data (base64) is required", nil);
      return;
    }
    int width = [image[@"width"] intValue];
    int height = [image[@"height"] intValue];
    NSString *formatStr = image[@"format"] ?: @"NV21";

    ASVLOFFSCREEN offscreen = OffscreenFromData(data, width, height, formatStr);

    // We need to ensure the engine is initialized with proper mask for these attributes.
    // If not, process() might fail or do nothing for those attributes.
    // For now, we assume initEngine was called with sufficient mask.

    // Run detection (which also runs process if mask is set in our Manager)
    [self.engineManager detectFaces:&offscreen];

    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    if (needAge) {
        result[@"ages"] = [self.engineManager getAges];
    }
    if (needGender) {
        result[@"genders"] = [self.engineManager getGenders];
    }
    if (needLiveness) {
        result[@"liveness"] = [self.engineManager getLiveness];
    }
    if (need3DAngle) {
        result[@"angles"] = [self.engineManager getFace3DAngles];
    }

    resolve(result);
}

RCT_EXPORT_METHOD(dbUpsert:(NSString *)userId
                  feature:(NSDictionary *)feature
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  asf_logI(@"dbUpsert userId=%@", userId);

  NSData *d = DataFromBase64(feature[@"dataBase64"]);
  if (!d) {
    reject(@"BAD_FEATURE", @"feature.dataBase64 required", nil);
    return;
  }

  [self.faceDB upsertFeatureData:d forUserId:userId];
  resolve(@(YES));
}

RCT_EXPORT_METHOD(dbRemove:(NSString *)userId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  asf_logI(@"dbRemove userId=%@", userId);

  [self.faceDB removeFeatureForUserId:userId];
  resolve(@(YES));
}

RCT_EXPORT_METHOD(dbSearch:(NSDictionary *)feature
                  topK:(double)topK
                  threshold:(double)threshold
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  asf_logD(@"dbSearch topK=%f threshold=%f", topK, threshold);

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
  asf_logI(@"dbClear");

  [self.faceDB clear];
  resolve(@(YES));
}

@end
