#import "ArcsoftFaceDB.h"

@implementation ArcsoftFaceDB {
  NSMutableDictionary<NSString *, NSString *> *_db;
}

- (instancetype)init {
  if (self = [super init]) {
    _db = [NSMutableDictionary new];
  }
  return self;
}

- (void)put:(NSString *)name featureBase64:(NSString *)feature {
  if (!name) return;
  _db[name] = feature ?: @"";
}

- (void)remove:(NSString *)name {
  if (!name) return;
  [_db removeObjectForKey:name];
}

- (NSArray<NSDictionary *> *)search:(NSString *)featureBase64 topN:(int)topN {
  // TODO(对照 ArcSoft iOS Demo): 用 SDK compare 计算 score 并排序，返回 topN
  NSMutableArray *arr = [NSMutableArray new];
  for (NSString *name in _db) {
    [arr addObject:@{@"name": name, @"score": @(0.9)}];
  }
  return arr;
}

@end
