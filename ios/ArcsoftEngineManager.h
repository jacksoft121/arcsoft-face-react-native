#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ArcsoftEngineManager : NSObject

- (BOOL)initEngine;
- (void)releaseEngine;

// NV21 base64 -> faces array (统一 TS 输出结构)
- (NSArray<NSDictionary *> *)detectNV21Base64:(NSString *)nv21Base64
                                        width:(int)width
                                       height:(int)height
                                      options:(NSDictionary *)options;

// NV21 base64 + faceIndex -> feature base64 (nullable)
- (NSString * _Nullable)extractFeatureNV21Base64:(NSString *)nv21Base64
                                           width:(int)width
                                          height:(int)height
                                       faceIndex:(int)faceIndex;

// feature base64 compare -> score
- (float)compareFeatureBase64:(NSString *)f1Base64 f2:(NSString *)f2Base64;

@end

NS_ASSUME_NONNULL_END
