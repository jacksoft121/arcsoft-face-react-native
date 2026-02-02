#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FaceRegistry : NSObject

+ (void)load;
+ (void)persist;

+ (void)upsert:(NSString *)userId feature:(NSData *)feature;
+ (void)remove:(NSString *)userId;
+ (void)clear;

+ (nullable NSData *)featureForUser:(NSString *)userId;
+ (NSDictionary<NSString *, NSData *> *)allFeatures;

@end

NS_ASSUME_NONNULL_END
