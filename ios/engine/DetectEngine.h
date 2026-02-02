#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngineDefine.h>

NS_ASSUME_NONNULL_BEGIN

@interface DetectEngine : NSObject

/// 单人脸 detect（返回 YES 表示检测到脸，outFaceInfo 写入）
+ (BOOL)detectFromNV12PixelBuffer:(CVPixelBufferRef)pixelBuffer
                         faceInfo:(ASF_SingleFaceInfo *)outFaceInfo;

@end

NS_ASSUME_NONNULL_END
