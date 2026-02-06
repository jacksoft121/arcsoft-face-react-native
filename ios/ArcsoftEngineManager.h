#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>
#import <ArcSoftFaceEngine/asvloffscreen.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngineDefine.h>

NS_ASSUME_NONNULL_BEGIN

/// ArcSoft FaceEngine 生命周期管理（初始化/释放/能力开关）
@interface ArcsoftEngineManager : NSObject

+ (instancetype)sharedInstance;

@property(nonatomic, readonly) BOOL inited;
@property(nonatomic, strong, readonly) ArcSoftFaceEngine *engine;

/// SDK 激活/注册
- (int)activateWithAppId:(NSString *)appId
                 sdkKey:(NSString *)sdkKey
              activeKey:(nullable NSString *)activeKey;

/// 获取激活文件信息
- (nullable NSDictionary *)getActiveFileInfo;

/// 初始化引擎
- (int)initEngineWithDetectMode:(ASF_DetectMode)detectMode
                 orientPriority:(ASF_OrientPriority)orientPriority
                     maxFaceNum:(int)maxFaceNum
                   combinedMask:(int)combinedMask;

- (void)uninit;

/// 人脸检测 (视频流)
- (NSArray<NSDictionary *> *)detectFaces:(ASVLOFFSCREEN *)offscreen;

/// 人脸检测 (图片)
- (NSArray<NSDictionary *> *)detectFacesFromImage:(UIImage *)image;

/// 提取人脸特征 (视频流)
- (nullable NSString *)extractFeature:(ASVLOFFSCREEN *)offscreen
                             faceRect:(MRECT)rect
                               orient:(int)orient;

/// 提取人脸特征 (图片)
- (nullable NSString *)extractFeatureFromImage:(UIImage *)image
                                      faceInfo:(NSDictionary *)faceInfo;

/// 特征比对
- (float)compareFeature1:(NSData *)f1 feature2:(NSData *)f2;

/// 年龄/性别/3D角度/活体等（需要 combinedMask 中打开对应能力）
- (NSArray<NSNumber *> *)getAges;
- (NSArray<NSNumber *> *)getGenders;
- (NSArray<NSDictionary *> *)getFace3DAngles;
- (NSArray<NSNumber *> *)getLiveness;

@end

NS_ASSUME_NONNULL_END
