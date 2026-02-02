#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>

NS_ASSUME_NONNULL_BEGIN

@interface DetectEngine : NSObject

/// 单人脸 detect（VIDEO 引擎）
/// 返回 YES 表示检测到人脸，并写入 outFaceInfo
+ (BOOL)detectFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
                     faceInfo:(ASF_FaceInfo *)outFaceInfo;

@end

NS_ASSUME_NONNULL_END
