#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ArcSoftFaceEngine;

@interface ArcFaceEnginePool : NSObject

/// 获取 VIDEO 模式引擎（detect/track）
+ (ArcSoftFaceEngine *)detectEngine;

/// 获取 IMAGE 模式引擎（extract/register）
+ (ArcSoftFaceEngine *)featureEngine;

@end

NS_ASSUME_NONNULL_END
