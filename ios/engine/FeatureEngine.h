#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>

NS_ASSUME_NONNULL_BEGIN

@interface FeatureEngine : NSObject

/// 从像素 buffer + faceInfo 提取特征（IMAGE 引擎）
/// 返回 NSData(feature bytes)，失败返回 nil
+ (nullable NSData *)extractFeatureFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                          faceInfo:(ASF_FaceInfo)faceInfo;

@end

NS_ASSUME_NONNULL_END
