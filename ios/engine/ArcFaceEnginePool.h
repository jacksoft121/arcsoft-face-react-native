#import <Foundation/Foundation.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>

NS_ASSUME_NONNULL_BEGIN

@interface ArcFaceEnginePool : NSObject

/// 初始化（内部 dispatch_once，只会做一次）
+ (void)initEnginesIfNeeded;

/// 串行使用 VIDEO 引擎（detect/track）
+ (void)withDetectEngine:(void (^)(ASF_FaceEngine engine))block;

/// 串行使用 IMAGE 引擎（extract / register）
+ (void)withFeatureEngine:(void (^)(ASF_FaceEngine engine))block;

@end

NS_ASSUME_NONNULL_END
