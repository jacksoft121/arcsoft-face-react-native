#import "ArcsoftFaceModule.h"
#import "ArcsoftEngineManager.h"
#import "ArcsoftFaceDB.h"

// 如果你 SDK 的头文件是 <ArcSoftFaceSDK/ArcSoftFaceSDK.h>，这里保留；
// 若你的 Demo 里不是这个名字，以 Demo 为准替换。
#import <ArcSoftFaceSDK/ArcSoftFaceSDK.h>

@implementation ArcsoftFaceModule {
  ArcsoftEngineManager *_mgr;
  ArcsoftFaceDB *_db;
}

RCT_EXPORT_MODULE(ArcsoftFace)

/// ✅ SDK 注册/激活（按你官方 iOS Demo 改这里）
RCT_EXPORT_METHOD(activate:(NSString *)appId
                  sdkKey:(NSString *)sdkKey
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  // TODO(对照 ArcSoft iOS Demo):
  // 例如：OnlineActivation(appId, sdkKey) / ASFOnlineActivation(...) / ASFActivation...
  // 成功 resolve(true)，失败 reject(code,msg)
  resolve(@YES);
}

RCT_EXPORT_METHOD(init:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  _mgr = [ArcsoftEngineManager new];
  _db = [ArcsoftFaceDB new];

  BOOL ok = [_mgr initEngine];
  if (ok) resolve(@YES);
  else reject(@"INIT_FAIL", @"ArcSoft init failed", nil);
}

RCT_EXPORT_METHOD(release)
{
  [_mgr releaseEngine];
  _mgr = nil;
  _db = nil;
}

/// ✅ detect：输入 NV21 base64，输出 FaceInfo[]
RCT_EXPORT_METHOD(detect:(NSString *)nv21Base64
                  width:(NSInteger)width
                  height:(NSInteger)height
                  options:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  resolve([_mgr detectNV21Base64:nv21Base64 width:(int)width height:(int)height options:options ?: @{}]);
}

/// ✅ extractFeature：输出 {data: base64} 或 null
RCT_EXPORT_METHOD(extractFeature:(NSString *)nv21Base64
                  width:(NSInteger)width
                  height:(NSInteger)height
                  faceIndex:(NSInteger)faceIndex
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSString *feature = [_mgr extractFeatureNV21Base64:nv21Base64 width:(int)width height:(int)height faceIndex:(int)faceIndex];
  if (!feature) { resolve((id)kCFNull); return; }
  resolve(@{@"data": feature});
}

/// ✅ compareFeature：输入两份特征 base64
RCT_EXPORT_METHOD(compareFeature:(NSString *)f1
                  f2:(NSString *)f2
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  resolve(@([_mgr compareFeatureBase64:f1 f2:f2]));
}

/// ✅ 人脸库（示例：内存库）
RCT_EXPORT_METHOD(registerFace:(NSString *)name
                  feature:(NSString *)feature
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  [_db put:name featureBase64:feature];
  resolve(@YES);
}

RCT_EXPORT_METHOD(removeFace:(NSString *)name
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  [_db remove:name];
  resolve(@YES);
}

RCT_EXPORT_METHOD(searchFace:(NSString *)feature
                  topN:(NSInteger)topN
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  resolve([_db search:feature topN:(int)topN]);
}

@end
