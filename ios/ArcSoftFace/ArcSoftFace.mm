#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

// ArcSoft iOS SDK
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngineDefine.h>

/**
 * ArcSoft FaceEngine iOS Bridge for React Native 0.78
 *
 * ✅ API 对齐 Android：activate / init / release / detect / extractFeature / compare
 *
 * 说明：本仓库不包含 ArcSoft SDK 二进制（.framework/.a），请你按官方 Demo 集成到宿主工程。
 */
@interface ArcsoftFace : NSObject <RCTBridgeModule>
@end

@implementation ArcsoftFace {
  ArcSoftFaceEngine *_engine;
  BOOL _inited;
}

RCT_EXPORT_MODULE(ArcsoftFace)

#pragma mark - Helpers

- (ArcSoftFaceEngine *)engine {
  if (_engine == nil) {
    _engine = [[ArcSoftFaceEngine alloc] init];
  }
  return _engine;
}

- (NSData *)dataFromBase64:(NSString *)b64 {
  if (b64 == nil) return nil;
  return [[NSData alloc] initWithBase64EncodedString:b64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

- (NSString *)base64FromBytes:(uint8_t *)bytes length:(int)len {
  if (bytes == NULL || len <= 0) return @"";
  NSData *d = [NSData dataWithBytes:bytes length:(NSUInteger)len];
  return [d base64EncodedStringWithOptions:0];
}

#pragma mark - Public API

/**
 * ✅ SDK 注册/激活（在线激活）
 * 对照官方 Demo：
 * - ArcSoftFaceEngineDemo/ui/ViewController.mm -> [self.faceEngine activeWithAppId:SDKKey:]
 */
RCT_EXPORT_METHOD(activate:(NSString *)appId
                  sdkKey:(NSString *)sdkKey
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  if (appId.length == 0 || sdkKey.length == 0) {
    reject(@"INVALID_ARGS", @"activate requires appId and sdkKey", nil);
    return;
  }

  // 逐行对照 Demo：
  // int code = [self.faceEngine activeWithAppId:APPID SDKKey:SDKKEY];
  int code = [[self engine] activeWithAppId:appId SDKKey:sdkKey];
  if (code == ASF_MOK) {
    resolve(@(YES));
  } else {
    reject(@"ACTIVATE_FAILED", [NSString stringWithFormat:@"ArcSoft activate failed: %d", code], nil);
  }
}

/**
 * ✅ 获取激活信息（可选）
 * 对照官方 Demo：
 * - ViewController.mm -> [self.faceEngine getActiveFileInfo:]
 */
RCT_EXPORT_METHOD(getActiveFileInfo:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  ASF_ActiveFileInfo info;
  memset(&info, 0, sizeof(info));

  int code = [[self engine] getActiveFileInfo:&info];
  if (code != ASF_MOK) {
    reject(@"GET_ACTIVE_INFO_FAILED", [NSString stringWithFormat:@"getActiveFileInfo failed: %d", code], nil);
    return;
  }

  // 只返回常用字段（避免结构体字段随 SDK 版本变化导致崩）
  NSMutableDictionary *out = [NSMutableDictionary dictionary];
  out[@"startTime"] = info.startTime ? [NSString stringWithUTF8String:info.startTime] : @"";
  out[@"endTime"]   = info.endTime ? [NSString stringWithUTF8String:info.endTime] : @"";
  out[@"platform"]  = info.platform ? [NSString stringWithUTF8String:info.platform] : @"";
  out[@"sdkType"]   = info.sdkType ? [NSString stringWithUTF8String:info.sdkType] : @"";

  resolve(out);
}

/**
 * ✅ 初始化引擎（检测/识别等能力）
 *
 * Android 你的 SDK 是 5 参数 init；iOS 这边保持默认参数可跑：
 * - detectMode: ASF_DETECT_MODE_IMAGE
 * - orient: ASF_OP_0_ONLY
 * - scale: 16
 * - maxFaceNum: 10
 */
RCT_EXPORT_METHOD(init:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  if (_inited) {
    resolve(@(YES));
    return;
  }

  // 对照官方 Demo：创建 ArcSoftFaceEngine 后调用 initFaceEngineWithDetectMode ...
  int code = [[self engine] initFaceEngineWithDetectMode:ASF_DETECT_MODE_IMAGE
                                         orientPriority:ASF_OP_0_ONLY
                                                  scale:16
                                           maxFaceNum:10
                                          combinedMask:0];

  if (code == ASF_MOK) {
    _inited = YES;
    resolve(@(YES));
  } else {
    reject(@"INIT_FAILED", [NSString stringWithFormat:@"ArcSoft init failed: %d", code], nil);
  }
}

RCT_EXPORT_METHOD(release) {
  if (_engine != nil) {
    [_engine unInitFaceEngine];
    _engine = nil;
  }
  _inited = NO;
}

/**
 * 人脸检测（NV21 Base64） -> 返回人脸数量
 */
RCT_EXPORT_METHOD(detectBase64:(NSString *)nv21Base64
                  width:(NSInteger)width
                  height:(NSInteger)height
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  if (!_inited) {
    reject(@"NOT_INITED", @"ArcSoft engine is not initialized", nil);
    return;
  }

  NSData *data = [self dataFromBase64:nv21Base64];
  if (data == nil || data.length == 0) {
    reject(@"INVALID_IMAGE", @"nv21Base64 is empty", nil);
    return;
  }

  // 关键：iOS SDK 的 format 直接用 ASVL_PAF_NV21
  NSArray<ASF_SingleFaceInfo *> *faces = [[self engine] detectFacesWithWidth:(int)width
                                                                      height:(int)height
                                                                      format:ASVL_PAF_NV21
                                                                        data:(unsigned char *)data.bytes];

  resolve(@(faces.count));
}

/**
 * 提取第一张脸的特征（NV21 Base64） -> 返回 feature Base64（便于跨端存储与比对）
 */
RCT_EXPORT_METHOD(extractFirstFeatureBase64:(NSString *)nv21Base64
                  width:(NSInteger)width
                  height:(NSInteger)height
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  if (!_inited) {
    reject(@"NOT_INITED", @"ArcSoft engine is not initialized", nil);
    return;
  }

  NSData *data = [self dataFromBase64:nv21Base64];
  if (data == nil || data.length == 0) {
    reject(@"INVALID_IMAGE", @"nv21Base64 is empty", nil);
    return;
  }

  NSArray<ASF_SingleFaceInfo *> *faces = [[self engine] detectFacesWithWidth:(int)width
                                                                      height:(int)height
                                                                      format:ASVL_PAF_NV21
                                                                        data:(unsigned char *)data.bytes];
  if (faces.count <= 0) {
    resolve(@"");
    return;
  }

  ASF_FaceFeature feature;
  memset(&feature, 0, sizeof(feature));

  int code = [[self engine] extractFaceFeatureWithWidth:(int)width
                                                height:(int)height
                                                format:ASVL_PAF_NV21
                                                  data:(unsigned char *)data.bytes
                                              faceInfo:faces.firstObject
                                           faceFeature:&feature];

  if (code != ASF_MOK || feature.pbFeature == NULL || feature.featureSize <= 0) {
    resolve(@"");
    return;
  }

  resolve([self base64FromBytes:feature.pbFeature length:feature.featureSize]);
}

/**
 * 特征比对：featureBase64 -> score
 */
RCT_EXPORT_METHOD(compareFeaturesBase64:(NSString *)featureA
                  featureB:(NSString *)featureB
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  if (!_inited) {
    reject(@"NOT_INITED", @"ArcSoft engine is not initialized", nil);
    return;
  }

  NSData *fa = [self dataFromBase64:featureA];
  NSData *fb = [self dataFromBase64:featureB];
  if (fa.length == 0 || fb.length == 0) {
    resolve(@(0));
    return;
  }

  ASF_FaceFeature f1;
  ASF_FaceFeature f2;
  memset(&f1, 0, sizeof(f1));
  memset(&f2, 0, sizeof(f2));

  f1.pbFeature = (MUInt8 *)fa.bytes;
  f1.featureSize = (int)fa.length;

  f2.pbFeature = (MUInt8 *)fb.bytes;
  f2.featureSize = (int)fb.length;

  ASF_FaceSimilar similar;
  memset(&similar, 0, sizeof(similar));

  int code = [[self engine] compareFaceFeatureWithFaceFeatureA:&f1
                                                 faceFeatureB:&f2
                                                   faceSimilar:&similar];

  if (code == ASF_MOK) {
    resolve(@(similar.score));
  } else {
    resolve(@(0));
  }
}

/**
 * 便捷：两张 NV21 Base64 直接比对 -> score
 */
RCT_EXPORT_METHOD(compareImagesBase64:(NSString *)nv21a
                  nv21b:(NSString *)nv21b
                  width:(NSInteger)width
                  height:(NSInteger)height
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  if (!_inited) {
    reject(@"NOT_INITED", @"ArcSoft engine is not initialized", nil);
    return;
  }

  // 先提特征再比对（对齐 Android 逻辑）
  __block NSString *fa = nil;
  __block NSString *fb = nil;

  // 同步执行（本方法计算量不大，若你要高性能可改为异步队列）
  {
    NSData *da = [self dataFromBase64:nv21a];
    NSData *db = [self dataFromBase64:nv21b];
    if (da.length == 0 || db.length == 0) {
      resolve(@(0));
      return;
    }

    NSArray<ASF_SingleFaceInfo *> *facesA = [[self engine] detectFacesWithWidth:(int)width height:(int)height format:ASVL_PAF_NV21 data:(unsigned char *)da.bytes];
    NSArray<ASF_SingleFaceInfo *> *facesB = [[self engine] detectFacesWithWidth:(int)width height:(int)height format:ASVL_PAF_NV21 data:(unsigned char *)db.bytes];
    if (facesA.count == 0 || facesB.count == 0) {
      resolve(@(0));
      return;
    }

    ASF_FaceFeature f1;
    ASF_FaceFeature f2;
    memset(&f1, 0, sizeof(f1));
    memset(&f2, 0, sizeof(f2));

    int c1 = [[self engine] extractFaceFeatureWithWidth:(int)width height:(int)height format:ASVL_PAF_NV21 data:(unsigned char *)da.bytes faceInfo:facesA.firstObject faceFeature:&f1];
    int c2 = [[self engine] extractFaceFeatureWithWidth:(int)width height:(int)height format:ASVL_PAF_NV21 data:(unsigned char *)db.bytes faceInfo:facesB.firstObject faceFeature:&f2];

    if (c1 != ASF_MOK || c2 != ASF_MOK || f1.pbFeature == NULL || f2.pbFeature == NULL) {
      resolve(@(0));
      return;
    }

    ASF_FaceSimilar similar;
    memset(&similar, 0, sizeof(similar));
    int code = [[self engine] compareFaceFeatureWithFaceFeatureA:&f1 faceFeatureB:&f2 faceSimilar:&similar];
    if (code == ASF_MOK) {
      resolve(@(similar.score));
    } else {
      resolve(@(0));
    }
  }
}

@end
