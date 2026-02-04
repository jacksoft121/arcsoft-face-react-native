#import <Foundation/Foundation.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>
#import <ArcSoftFaceEngine/asvloffscreen.h>

NS_ASSUME_NONNULL_BEGIN

/// ArcSoft FaceEngine 生命周期管理（初始化/释放/能力开关）
/// 逐行对照官方 iOS Demo：engine/ASFVideoProcessor.* / engine/ASFImageProcessor.*
@interface ArcsoftEngineManager : NSObject

@property(nonatomic, readonly) BOOL inited;
@property(nonatomic, strong, readonly) ArcSoftFaceEngine *engine;

/// SDK 激活/注册
/// - Parameters:
///   - appId: ArcSoft APP_ID
///   - sdkKey: ArcSoft SDK_KEY (iOS)
///   - activeKey: ArcSoft ACTIVE_KEY (如你的版本需要)
- (int)activateWithAppId:(NSString *)appId
                 sdkKey:(NSString *)sdkKey
              activeKey:(nullable NSString *)activeKey;

/// 初始化引擎（IMAGE 模式）
/// - Parameters:
///   - detectMode: ASF_DETECT_MODE_IMAGE / ASF_DETECT_MODE_VIDEO
///   - orientPriority: 方向优先级
///   - maxFaceNum: 最大人脸数
///   - combinedMask: 能力掩码（比如 ASF_FACE_DETECT | ASF_FACERECOGNITION | ASF_AGE ...）
- (int)initEngineWithDetectMode:(ASF_DETECT_MODE)detectMode
                 orientPriority:(ASF_OP_0_ONLY)orientPriority
                     maxFaceNum:(int)maxFaceNum
                   combinedMask:(int)combinedMask;

- (void)uninit;

/// 人脸检测
- (NSArray<NSDictionary *> *)detectFaces:(ASVLOFFSCREEN *)offscreen;

/// 提取人脸特征（feature base64）
- (nullable NSString *)extractFeature:(ASVLOFFSCREEN *)offscreen
                             faceRect:(MRECT)rect
                               orient:(int)orient;

/// 特征比对
- (float)compareFeature1:(NSData *)f1 feature2:(NSData *)f2;

/// 年龄/性别/3D角度/活体等（需要 combinedMask 中打开对应能力）
- (NSArray<NSNumber *> *)getAges;
- (NSArray<NSNumber *> *)getGenders;
- (NSArray<NSDictionary *> *)getFace3DAngles;
- (NSArray<NSNumber *> *)getLiveness;

@end

NS_ASSUME_NONNULL_END
