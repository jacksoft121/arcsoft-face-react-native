#import "ArcsoftFaceDB.h"

@interface ArcsoftFaceDB ()
@property(nonatomic, strong) NSMutableDictionary<NSString *, ArcSoftFaceFeature *> *map;
@end

@implementation ArcsoftFaceDB

- (instancetype)init {
  if (self = [super init]) {
    _map = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)upsertFeature:(ArcSoftFaceFeature *)feature forUserId:(NSString *)userId {
  if (!userId.length || feature == nil) return;
  self.map[userId] = feature;
}

- (void)removeFeatureForUserId:(NSString *)userId {
  if (!userId.length) return;
  [self.map removeObjectForKey:userId];
}

- (nullable ArcSoftFaceFeature *)featureForUserId:(NSString *)userId {
  return self.map[userId];
}

- (void)clear {
  [self.map removeAllObjects];
}

- (NSDictionary<NSString *, ArcSoftFaceFeature *> *)allFeatures {
  return [self.map copy];
}

@end
