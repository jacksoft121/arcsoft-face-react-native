#import <Foundation/Foundation.h>

@class ArcSoftFaceEngine;

NS_ASSUME_NONNULL_BEGIN

@interface ArcsoftFaceDB : NSObject

- (instancetype)init;

/// 插入/更新：userId -> 特征bytes
- (BOOL)upsertFeatureData:(NSData *)featureData
                forUserId:(NSString *)userId
               withEngine:(ArcSoftFaceEngine *)engine;

/// 删除某个 userId 的特征
- (BOOL)removeFeatureForUserId:(NSString *)userId
                    withEngine:(ArcSoftFaceEngine *)engine;

/// 清空
- (BOOL)clearWithEngine:(ArcSoftFaceEngine *)engine;

/// 获取数量
- (NSInteger)countWithEngine:(ArcSoftFaceEngine *)engine;

/// 逐个比对（本地 map），返回 topK（按 score 降序）
/// 返回结构：[{ userId: NSString, score: NSNumber }, ...]
- (NSDictionary * _Nullable)searchWithEngine:(ArcSoftFaceEngine *)engine
                                 featureData:(NSData *)featureData
                                   threshold:(float)threshold;

@end

NS_ASSUME_NONNULL_END
