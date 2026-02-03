#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ArcSoftFaceManager : NSObject

+ (instancetype)shared;

/** SDK 激活（Demo 第一步） */
- (int)activateWithAppId:(NSString *)appId
                  sdkKey:(NSString *)sdkKey;

/** 初始化引擎 */
- (int)initEngine;

/** 人脸检测 */
- (NSArray *)detectFacesFromNV21:(NSData *)nv21
                            width:(int)width
                           height:(int)height;

/** 特征提取 */
- (NSDictionary *)extractFeatureFromNV21:(NSData *)nv21
                                   width:(int)width
                                  height:(int)height
                               faceIndex:(int)faceIndex;

/** 人脸比对 */
- (float)compareFeature:(NSData *)f1 with:(NSData *)f2;

/** 活体检测 */
- (NSArray *)livenessFromNV21:(NSData *)nv21
                        width:(int)width
                       height:(int)height
                    faceInfos:(NSArray *)faces;

- (void)releaseEngine;

@end

NS_ASSUME_NONNULL_END
