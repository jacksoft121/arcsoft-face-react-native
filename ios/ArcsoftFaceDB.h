#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ArcsoftFaceDB : NSObject
- (void)put:(NSString *)name featureBase64:(NSString *)feature;
- (void)remove:(NSString *)name;
- (NSArray<NSDictionary *> *)search:(NSString *)featureBase64 topN:(int)topN;
@end

NS_ASSUME_NONNULL_END
