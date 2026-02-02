#import "FeatureEngine.h"
#import "ArcFaceEnginePool.h"
#import "PixelBufferUtils.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>

@implementation FeatureEngine

+ (NSData *)extractFeatureFromNV12PixelBuffer:(CVPixelBufferRef)pixelBuffer
                                     faceInfo:(ASF_SingleFaceInfo)faceInfo {
  int w = 0, h = 0;
  NSData *nv12 = [PixelBufferUtils copyNV12Bytes:pixelBuffer width:&w height:&h];
  if (!nv12) return nil;

  ArcSoftFaceEngine *engine = [ArcFaceEnginePool featureEngine];

  ASF_FaceFeature feature = {0};
  MRESULT mr = [engine extractFaceFeatureWithWidth:w
                                            height:h
                                              data:(MUInt8 *)nv12.bytes
                                            format:ASVL_PAF_NV12
                                          faceInfo:&faceInfo
                                           feature:&feature];

  if (mr != MOK) return nil;

  // 关键：你 SDK 里 ASF_FaceFeature 的字段名是 feature / featureSize（见文档）:contentReference[oaicite:6]{index=6}
  if (feature.feature == NULL || feature.featureSize <= 0) return nil;

  return [NSData dataWithBytes:feature.feature length:(NSUInteger)feature.featureSize];
}

@end
