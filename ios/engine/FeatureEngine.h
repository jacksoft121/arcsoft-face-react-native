#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngineDefine.h>

NS_ASSUME_NONNULL_BEGIN

@interface FeatureEngine : NSObject

+ (nullable NSData *)extractFeatureFromNV12PixelBuffer:(CVPixelBufferRef)pixelBuffer
                                              faceInfo:(ASF_SingleFaceInfo)faceInfo;

@end

NS_ASSUME_NONNULL_END
