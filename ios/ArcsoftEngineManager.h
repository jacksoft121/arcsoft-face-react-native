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
/// @param appId 应用ID
/// @param sdkKey SDK密钥
/// @param activeKey 激活码（可选）
/// @return 错误码 (MOK 为成功)
- (int)activateWithAppId:(NSString *)appId
                 sdkKey:(NSString *)sdkKey
              activeKey:(nullable NSString *)activeKey;

/// 获取激活文件信息
/// @return 包含激活信息的字典，失败返回 nil
- (nullable NSDictionary *)getActiveFileInfo;

/// 初始化引擎
/// @param detectMode 检测模式 (VIDEO/IMAGE)
/// @param orientPriority 人脸角度优先级
/// @param maxFaceNum 最大检测人脸数
/// @param combinedMask 功能组合掩码
/// @return 错误码
- (int)initEngineWithDetectMode:(ASF_DetectMode)detectMode
                 orientPriority:(ASF_OrientPriority)orientPriority
                     maxFaceNum:(int)maxFaceNum
                   combinedMask:(int)combinedMask;

/// 销毁引擎
- (void)uninit;

/// 人脸检测 (视频流)
/// @param offscreen 图像数据结构体
/// @return 检测到的人脸信息数组
- (NSArray<NSDictionary *> *)detectFaces:(ASVLOFFSCREEN *)offscreen;

/// 人脸检测 (图片)
/// @param image UIImage 对象
/// @return 检测到的人脸信息数组
- (NSArray<NSDictionary *> *)detectFacesFromImage:(UIImage *)image;

/// 提取人脸特征 (视频流)
/// @param offscreen 图像数据
/// @param rect 人脸框
/// @param orient 人脸角度
/// @param faceDataInfo 人脸数据信息 (必须从 detectFaces 结果中获取)
/// @return Base64 编码的特征数据
- (nullable NSString *)extractFeature:(ASVLOFFSCREEN *)offscreen
                             faceRect:(MRECT)rect
                               orient:(int)orient
                         faceDataInfo:(nullable NSData *)faceDataInfo;

/// 提取人脸特征 (图片)
/// @param image UIImage 对象
/// @param faceInfo 人脸信息字典
/// @return Base64 编码的特征数据
- (nullable NSString *)extractFeatureFromImage:(UIImage *)image
                                      faceInfo:(NSDictionary *)faceInfo;

/// 特征比对
/// @param f1 特征1数据
/// @param f2 特征2数据
/// @return 相似度 (0.0 - 1.0)
- (float)compareFeature1:(NSData *)f1 feature2:(NSData *)f2;

/// 获取年龄（需要 combinedMask 中打开对应能力）
- (NSArray<NSNumber *> *)getAges;
/// 获取性别
- (NSArray<NSNumber *> *)getGenders;
/// 获取3D角度
- (NSArray<NSDictionary *> *)getFace3DAngles;
/// 获取活体值
- (NSArray<NSNumber *> *)getLiveness;

// =========================
// Face DB (in-engine DB)
// =========================

/// 插入/更新人脸特征
/// @param userId 用户ID
/// @param featureData 特征数据
/// @return 是否成功
- (BOOL)faceDBAddOrUpdate:(NSString *)userId featureData:(NSData *)featureData;

/// 删除某个 userId 的特征
/// @param userId 用户ID
/// @return 是否成功
- (BOOL)faceDBRemove:(NSString *)userId;

/// 清空人脸库
/// @return 是否成功
- (BOOL)faceDBClear;

/// 获取人脸库数量
/// @return 数量
- (NSInteger)faceDBCount;

/// 获取所有人脸列表
/// @return 包含 { "id": userId } 的数组
- (NSArray<NSDictionary *> *)faceDBGetAllFaces;

/// 逐个比对（本地 map），返回 topK（按 score 降序）
/// @param featureData 待搜索的特征数据
/// @param threshold 相似度阈值
/// @return 结果字典 { "id": userId, "score": NSNumber }，未找到返回 nil
- (NSDictionary * _Nullable)faceDBSearchTop1:(NSData *)featureData threshold:(float)threshold;

@end

NS_ASSUME_NONNULL_END
