#import <Foundation/Foundation.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>

NS_ASSUME_NONNULL_BEGIN

/// 人脸库：内存实现（可扩展持久化）
/// iOS Demo 对照：
/// - 你提供的 Demo 中通常在业务层自己存储 FaceFeature，这里抽象成独立类。
@interface ArcsoftFaceDB : NSObject

/// 保存/更新一条特征
- (void)upsertFeature:(ArcSoftFaceFeature *)feature forUserId:(NSString *)userId;

/// 删除
- (void)removeFeatureForUserId:(NSString *)userId;

/// 清空
- (void)clear;

/// 批量取出（用于遍历检索）
- (NSDictionary<NSString *, ArcSoftFaceFeature *> *)allFeatures;

@end

NS_ASSUME_NONNULL_END
