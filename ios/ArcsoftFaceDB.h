#import <Foundation/Foundation.h>

@class ArcSoftFaceEngine;

NS_ASSUME_NONNULL_BEGIN

@interface ArcsoftFaceDB : NSObject

- (instancetype)init;

/// 插入/更新：userId -> 特征bytes
- (void)upsertFeatureData:(NSData *)featureData forUserId:(NSString *)userId;

/// 删除某个 userId 的特征
- (void)removeFeatureForUserId:(NSString *)userId;

/// 清空
- (void)clear;

/// 逐个比对（本地 map），返回 topK（按 score 降序）
/// 返回结构：[{ userId: NSString, score: NSNumber }, ...]
- (NSArray<NSDictionary *> *)searchWithEngine:(ArcSoftFaceEngine *)engine
                                  featureData:(NSData *)featureData
                                         topK:(NSInteger)topK
                                    threshold:(float)threshold;

@end

NS_ASSUME_NONNULL_END
