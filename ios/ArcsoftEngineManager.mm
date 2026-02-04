#import "ArcsoftEngineManager.h"
#import <UIKit/UIKit.h>

@implementation ArcsoftEngineManager {
  BOOL _inited;
  void *_engine; // TODO: 替换成你 SDK 的引擎句柄类型/对象
}

- (BOOL)initEngine {
  if (_inited) return YES;

  // TODO(对照 ArcSoft iOS Demo):
  // 1) 如果需要激活/授权检查，放在 module.activate 里做
  // 2) 创建引擎（例如 InitEngine / InitEngineEx / CreateEngine... 以你 Demo 为准）
  // _engine = ...
  _engine = (void *)0x1; // placeholder
  _inited = (_engine != NULL);
  return _inited;
}

- (void)releaseEngine {
  if (!_inited) return;

  // TODO(对照 ArcSoft iOS Demo): 释放引擎
  // UnInitEngine(_engine) ...
  _engine = NULL;
  _inited = NO;
}

static NSData * _Nullable b64ToData(NSString *b64) {
  if (b64.length == 0) return nil;
  return [[NSData alloc] initWithBase64EncodedString:b64 options:0];
}

- (NSArray<NSDictionary *> *)detectNV21Base64:(NSString *)nv21Base64
                                        width:(int)width
                                       height:(int)height
                                      options:(NSDictionary *)options
{
  if (!_inited) return @[];
  NSData *nv21 = b64ToData(nv21Base64);
  if (!nv21) return @[];

  // TODO(对照 ArcSoft iOS Demo):
  // A) 构造输入图（NV21）offscreen/ASVLOFFSCREEN 等（以你 iOS Demo 的 struct 为准）
  // B) 调用人脸检测，拿到 faceList
  // C) 按 options 决定是否处理：年龄/性别/活体/3D角度
  //
  // 统一返回结构（TS 端直接用）：
  // [
  //   {
  //     rect:{left,top,right,bottom,orient?},
  //     age?, gender?, liveness?,
  //     yaw?, pitch?, roll?
  //   },
  //   ...
  // ]
  return @[];
}

- (NSString * _Nullable)extractFeatureNV21Base64:(NSString *)nv21Base64
                                           width:(int)width
                                          height:(int)height
                                       faceIndex:(int)faceIndex
{
  if (!_inited) return nil;
  NSData *nv21 = b64ToData(nv21Base64);
  if (!nv21) return nil;

  // TODO(对照 ArcSoft iOS Demo):
  // 1) detect faces
  // 2) 选择 faceIndex
  // 3) extract feature -> NSData
  // 4) return base64 string
  return nil;
}

- (float)compareFeatureBase64:(NSString *)f1Base64 f2:(NSString *)f2Base64 {
  if (!_inited) return 0.f;

  NSData *f1 = b64ToData(f1Base64);
  NSData *f2 = b64ToData(f2Base64);
  if (!f1 || !f2) return 0.f;

  // TODO(对照 ArcSoft iOS Demo): compare -> score
  return 0.f;
}

@end
