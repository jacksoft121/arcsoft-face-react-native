#import "DetectEngine.h"
#import "ArcFaceEnginePool.h"
#import "PixelBufferUtils.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>

@implementation DetectEngine

+ (BOOL)detectFromNV12PixelBuffer:(CVPixelBufferRef)pixelBuffer
                         faceInfo:(ASF_SingleFaceInfo *)outFaceInfo {
  if (!pixelBuffer) return NO;

  ASVLOFFSCREEN offscreen = [PixelBufferUtils offscreenFromPixelBuffer:pixelBuffer];

  // 注意：detectFaces 接口需要 raw data/width/height/format，文档里也给了:contentReference[oaicite:5]{index=5}
  ArcSoftFaceEngine *engine = [ArcFaceEnginePool detectEngine];

  ASF_MultiFaceInfo faces = {0};
  MRESULT mr = [engine detectFacesWithWidth:offscreen.i32Width
                                     height:offscreen.i32Height
                                       data:offscreen.ppu8Plane[0] // NV12: 传入指向Y平面起始的连续内存不一定成立
                                     format:ASVL_PAF_NV12
                                    faceRes:&faces];

  if (mr != MOK || faces.faceNum < 1) return NO;

  // 组装单脸信息
  ASF_SingleFaceInfo one = {0};
  one.faceRect = faces.faceRect[0];
  one.faceOrient = faces.faceOrient[0];
  one.faceDataInfo = faces.faceDataInfoList[0];

  *outFaceInfo = one;
  return YES;
}

@end
