#import "ArcsoftFaceDB.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>

@interface ArcsoftFaceDB ()
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSData *> *map;
@end

@implementation ArcsoftFaceDB

- (instancetype)init {
    if (self = [super init]) {
        _map = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)upsertFeatureData:(NSData *)featureData forUserId:(NSString *)userId {
    if (!userId.length || !featureData.length) return;
    self.map[userId] = featureData;
}

- (void)removeFeatureForUserId:(NSString *)userId {
    if (!userId.length) return;
    [self.map removeObjectForKey:userId];
}

- (void)clear {
    [self.map removeAllObjects];
}

- (NSArray<NSDictionary *> *)searchWithEngine:(ArcSoftFaceEngine *)engine
                                  featureData:(NSData *)featureData
                                         topK:(NSInteger)topK
                                    threshold:(float)threshold {

    if (!engine || !featureData.length) return @[];
    if (topK <= 0) topK = 1;

    // ✅ 关键：__block，避免在 block 内变成 const，导致 &query 变成 const ASF_FaceFeature*
    __block ASF_FaceFeature query;
    query.feature = (MByte *)featureData.bytes;
    query.featureSize = (MInt32)featureData.length;

    NSMutableArray<NSDictionary *> *results = [NSMutableArray array];

    [self.map enumerateKeysAndObjectsUsingBlock:^(NSString *userId, NSData *data, BOOL *stop) {
        if (!data.length) return;

        // ✅ 同样 __block，避免 &target 变 const
        __block ASF_FaceFeature target;
        target.feature = (MByte *)data.bytes;
        target.featureSize = (MInt32)data.length;

        MFloat confidence = 0.0f;

        // ✅ 使用你贴出来的 SDK 正确方法
        MRESULT mr = [engine compareFaceWithFeature:&query
                                           feature2:&target
                                    confidenceLevel:&confidence];

        if (mr == MOK && confidence >= threshold) {
            [results addObject:@{
                @"userId": userId ?: @"",
                @"score": @(confidence)
            }];
        }
    }];

    [results sortUsingDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO]
    ]];

    if (results.count > (NSUInteger)topK) {
        return [results subarrayWithRange:NSMakeRange(0, topK)];
    }
    return results;
}

@end
