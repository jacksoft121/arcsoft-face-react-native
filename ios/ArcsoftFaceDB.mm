#import "ArcsoftFaceDB.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>

@interface ArcsoftFaceDB ()
// userId (String) -> searchId (Int)
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *userToSearchId;
// searchId (Int) -> userId (String)
@property(nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *searchIdToUser;
// 自增 ID 计数器
@property(nonatomic, assign) int nextSearchId;
@end

@implementation ArcsoftFaceDB

- (instancetype)init {
    if (self = [super init]) {
        _userToSearchId = [NSMutableDictionary dictionary];
        _searchIdToUser = [NSMutableDictionary dictionary];
        _nextSearchId = 1000; // 从 1000 开始，避免与系统保留 ID 冲突
    }
    return self;
}

- (BOOL)upsertFeatureData:(NSData *)featureData
                forUserId:(NSString *)userId
               withEngine:(ArcSoftFaceEngine *)engine {
    if (!userId.length || !featureData.length || !engine) return NO;

    // 1. 检查是否已存在
    NSNumber *existingId = self.userToSearchId[userId];
    if (existingId) {
        // 如果已存在，先移除旧的（ArcSoft SDK 没有直接 update 接口，通常是 remove + register）
        // 或者使用 updateFaceFeatureWithFeatureInfo，但需要构造完整 Info
        // 这里简单起见：先 remove 再 register
        [self removeFeatureForUserId:userId withEngine:engine];
    }

    // 2. 分配新 ID
    int searchId = self.nextSearchId++;

    // 3. 构造注册信息
    // 修正：ASF_FaceFeatureInfo 的 feature 字段是 ASF_FaceFeature 结构体指针
    ASF_FaceFeature featureStruct = {0};
    featureStruct.feature = (MByte *)featureData.bytes;
    featureStruct.featureSize = (MInt32)featureData.length;

    ASF_FaceFeatureInfo info = {0};
    info.searchId = searchId;
    info.feature = &featureStruct;
    // tag 可以存 userId，但长度有限制，这里只用 searchId 关联
    info.tag = "";

    // 4. 调用引擎注册
    MRESULT mr = [engine registerSingleFaceFeatureWithFeatureInfo:&info];
    if (mr == MOK) {
        // 5. 更新映射
        self.userToSearchId[userId] = @(searchId);
        self.searchIdToUser[@(searchId)] = userId;
        return YES;
    }

    return NO;
}

- (BOOL)removeFeatureForUserId:(NSString *)userId
                    withEngine:(ArcSoftFaceEngine *)engine {
    if (!userId.length || !engine) return NO;

    NSNumber *searchId = self.userToSearchId[userId];
    if (!searchId) return NO;

    MRESULT mr = [engine removeFaceFeatureWithSearchId:[searchId intValue]];

    // 无论引擎返回成功与否（可能引擎里已经没了），都清理本地映射
    [self.userToSearchId removeObjectForKey:userId];
    [self.searchIdToUser removeObjectForKey:searchId];

    return (mr == MOK);
}

- (BOOL)clearWithEngine:(ArcSoftFaceEngine *)engine {
    if (!engine) return NO;

    MRESULT mr = [engine clearAllFaceFeature];

    [self.userToSearchId removeAllObjects];
    [self.searchIdToUser removeAllObjects];
    self.nextSearchId = 1000;

    return (mr == MOK);
}

- (NSInteger)countWithEngine:(ArcSoftFaceEngine *)engine {
    if (!engine) return 0;

    MInt32 count = 0;
    MRESULT mr = [engine getFaceCount:&count];
    if (mr == MOK) {
        return (NSInteger)count;
    }
    return 0;
}

- (NSDictionary * _Nullable)searchWithEngine:(ArcSoftFaceEngine *)engine
                                 featureData:(NSData *)featureData
                                   threshold:(float)threshold {
    if (!engine || !featureData.length) return nil;

    ASF_FaceFeature feature = {0};
    feature.feature = (MByte *)featureData.bytes;
    feature.featureSize = (MInt32)featureData.length;

    ASF_FaceFeatureInfo resultInfo = {0};
    MFloat confidence = 0.0f;

    // 1:N 搜索
    MRESULT mr = [engine searchFaceFeatureWithFeature:&feature
                                         compareModel:ASF_LIFE_PHOTO // 或 ASF_ID_PHOTO
                                           similarity:&confidence
                                      faceFeatureInfo:&resultInfo];

    if (mr == MOK && confidence >= threshold) {
        // 反查 userId
        NSString *userId = self.searchIdToUser[@(resultInfo.searchId)];
        if (userId) {
            return @{
                @"id": userId,
                @"score": @(confidence)
            };
        }
    }

    return nil;
}

@end
