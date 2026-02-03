//
//  ArcSoftFaceEngine.h
//  ArcSoftFaceEngine
//
//  Created by arc-mac-m4 on 2025/9/18.
//

#import <Foundation/Foundation.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngineDefine.h>
#import <ArcSoftFaceEngine/ArcSoftActiveInfo.h>

//! Project version number for ArcSoftFaceEngine.
FOUNDATION_EXPORT double ArcSoftFaceEngineVersionNumber;

//! Project version string for ArcSoftFaceEngine.
FOUNDATION_EXPORT const unsigned char ArcSoftFaceEngineVersionString[];


// In this header, you should import all the public headers of your framework using statements like #import <ArcSoftFaceEngine/PublicHeader.h>

@interface ArcSoftFaceEngine : NSObject
- (instancetype)init;

/*!
 * @brief 引擎激活
 * @param appId         官网获取的APPID
 * @param sdkkey        官网获取的SDKKEY
 * @return              成功返回MOK或MERR_ASF_ALREADY_ACTIVATED，否则返回失败code
 */
-(MRESULT)activeWithAppId:(NSString *)appId
                    SDKKey:(NSString *)sdkkey;

		
/*!
 * @brief 引擎初始化
 * @param detectMode                    检测模式（ASF_DETECT_MODE_VIDEO或ASF_DETECT_MODE_IMAGE模式）
 * @param detectFaceOrientPriority      检测脸部的角度优先值，推荐仅检测单一角度，效果更优
 * @param detectFaceMaxNum              最大需要检测的人脸个数[1,10]
 * @param combinedMask                  用户选择需要检测的功能组合，可单个或多个
 * @return                              成功返回MOK，否则返回失败code
 */
-(MRESULT)initFaceEngineWithDetectMode:(ASF_DetectMode)detectMode
                        orientPriority:(ASF_OrientPriority)detectFaceOrientPriority
                            maxFaceNum:(MInt32)detectFaceMaxNum
                          combinedMask:(MInt32)combinedMask;


/*!
 * @brief                   人脸检测
 * @param width             图像数据宽度
 * @param height            图像数据高度
 * @param data              图像数据
 * @param format            颜色空间格式
 * @param detectedFaces     检测到的人脸信息
 * @return                  成功返回MOK，否则返回失败code
 */
-(MRESULT)detectFacesWithWidth:(MInt32)width
                        height:(MInt32)height
                          data:(MUInt8*)data
                        format:(MInt32)format
                       faceRes:(LPASF_MultiFaceInfo)detectedFaces;

/*!
 * @brief                   人脸信息检测（年龄/性别/活体），最多支持4张人脸信息检测，超过部分返回未知
 * @param width             图像数据宽度
 * @param height            图像数据高度
 * @param data              图像数据
 * @param format            颜色空间格式
 * @param detectedFaces     检测到的人脸信息
 * @param combinedMask      初始化中参数combinedMask与ASF_AGE|ASF_GENDER|ASF_LIVENESS的交集的子集
 * @return                  成功返回MOK，否则返回失败code
 */
-(MRESULT)processWithWidth:(MInt32)width
                    height:(MInt32)height
                      data:(MUInt8*)data
                    format:(MInt32)format
                   faceRes:(LPASF_MultiFaceInfo)detectedFaces
                      mask:(MInt32)combinedMask;



/*!
 * @brief   获取版本信息
 * @return  成功返回版本信息，否则返回MNull
 */
- (NSString*)getVersion;

/*!
 * @brief               获取激活文件信息
 * @param activeInfo         激活文件信息对象
 * @return              成功返回MOK，否则返回失败code
 */
- (MRESULT)getActiveFileInfo:(ArcSoftActiveInfo*)activeInfo;

/*!
 * @brief               获取激活文件信息
 * @return              成功返回MOK，否则返回失败code
 */
- (MRESULT)unInitFaceEngine;


@end

	
@interface ArcSoftFaceEngine(FaceRecoginition)


/*!
 * @brief               提取人脸特征信息
 * @param width                    图像宽度
 * @param height                  图像高度
 * @param data                       图像数据
 * @param format                   图像格式
 * @param faceInfo              人脸信息
 * @param feature                 人脸特征信息
 * @return              成功返回MOK，否则返回失败code
 */
-(MRESULT)extractFaceFeatureWithWidth:(MInt32)width
                               height:(MInt32)height
                                 data:(MUInt8 *)data
                               format:(MInt32)format
                             faceInfo:(LPASF_SingleFaceInfo)faceInfo
                              feature:(LPASF_FaceFeature)feature;


/*!
 * @brief                          人脸特征信息比对
 * @param feature1                                      待比对人脸特征信息
 * @param feature2                                      待比对人脸特征信息
 * @param confidenceLevel                       置信度
 * @return                          成功返回MOK，否则返回失败code
 */
- (MRESULT)compareFaceWithFeature:(LPASF_FaceFeature)feature1
                         feature2:(LPASF_FaceFeature)feature2
                  confidenceLevel:(MFloat*)confidenceLevel;



/*!
 * @brief                          人脸特征信息比对
 * @param feature1                                      待比对人脸特征信息
 * @param feature2                                      待比对人脸特征信息
 * @param compareModel                              比对模式
 * @param confidenceLevel                       置信度
 * @return                          成功返回MOK，否则返回失败code
 */
- (MRESULT)compareFaceWithFeature:(LPASF_FaceFeature)feature1
                         feature2:(LPASF_FaceFeature)feature2
                     compareModel:(ASF_CompareModel)compareModel
                  confidenceLevel:(MFloat*)confidenceLevel;




/*!
 * @brief                          查询相似度最高的人脸特征信息(1VN)
 * @param feature                                      待比对人脸特征信息
 * @param compareModel                                      比对模式
 * @param confidenceLevel                       置信度
 * @param featureInfo                       人脸特征信息
 * @return                          成功返回MOK，否则返回失败code
 */

- (MRESULT)searchFaceFeatureWithFeature:(LPASF_FaceFeature) feature
                           compareModel:(ASF_CompareModel)compareModel
                             similarity:(MFloat*)confidenceLevel
                        faceFeatureInfo:(LPASF_FaceFeatureInfo) featureInfo;


/*!
 * @brief                          查询相似度靠前的N个的人脸特征信息(nVN)
 * @param feature                                      待比对人脸特征信息
 * @param topN                                             搜索的数量
 * @param compareModel                          比对模式
 * @param faceSearchResultGroup                       人脸特征信息集合
 * @return                          成功返回MOK，否则返回失败code
 */

- (MRESULT)searchFaceFeatureTopNWithFeature:(LPASF_FaceFeature) feature
                                  searchNum:(MInt32)topN
                               compareModel:(ASF_CompareModel)compareModel
                      faceSearchResultGroup:(LPASF_FaceFeatureSearchResult)faceSearchResultGroup;



/*!
 * @brief                          批量注册人脸特征信息
 * @param featureInfoList                                      人脸特征信息列表
 * @param size                                                人脸特征数量
 * @return                          成功返回MOK，否则返回失败code
 */
- (MRESULT)registerFaceFeatureWithFeatureInfoList:(LPASF_FaceFeatureInfo) featureInfoList
                                      registerNum:(MInt32)size;



/*!
 * @brief                          注册单张人脸特征信息
 * @param featureInfo                                      人脸特征信息
 * @return                          成功返回MOK，否则返回失败code
 */
- (MRESULT)registerSingleFaceFeatureWithFeatureInfo:(LPASF_FaceFeatureInfo) featureInfo;

/*!
 * @brief                          移除指定人脸特征信息
 * @param searchId                                      人脸查询ID
 * @return                          成功返回MOK，否则返回失败code
 */
- (MRESULT)removeFaceFeatureWithSearchId:(MInt32)searchId;

/*!
 * @brief                          清空人脸特征信息
 * @return                          成功返回MOK，否则返回失败code
 */
- (MRESULT)clearAllFaceFeature;

/*!
 * @brief                          更新人脸特征信息
 * @param featureInfo                                      人脸特征信息
 * @return                          成功返回MOK，否则返回失败code
 */
- (MRESULT)updateFaceFeatureWithFeatureInfo:(LPASF_FaceFeatureInfo)featureInfo;

/*!
 * @brief                          根据searchID获取人脸特征信息
 * @param searchId                                      人脸searchID
 * @param featureInfo                                人脸特征信息
 * @return                          成功返回MOK，否则返回失败code
 */
- (MRESULT)getFaceFeatureWithSearchId:(MInt32)searchId
                      faceFeatureInfo:(LPASF_FaceFeatureInfo)featureInfo;

/*!
 * @brief                           获取当前已经注册的人脸数量
 * @param num                                                   人脸数量
 * @return                          成功返回MOK，否则返回失败code
 */
- (MRESULT)getFaceCount:(MInt32*)num;


@end


@interface ArcSoftFaceEngine(AgeEstimation)

/*!
 * @brief                          获取年龄结果
 * @param ageInfo                                       年龄信息数组
 * @return                          成功返回MOK，否则返回失败code
 */
- (MRESULT)getAge:(LPASF_AgeInfo) ageInfo;

@end


@interface ArcSoftFaceEngine(GenderEstimation)

/*!
 * @brief                            获取性别信息
 * @param genderInfo                                      性别信息数组
 * @return                          成功返回MOK，否则返回失败code
 */
- (MRESULT)getGender:(LPASF_GenderInfo) genderInfo;

@end



@interface ArcSoftFaceEngine(FaceLiveness)

/*!
 * @brief                           设置RGB活体阈值
 * @param livenessThreshold                     活体阈值
 * @return                          成功返回MOK，否则返回失败code
 */
- (MRESULT)setLivenessThreshold:(LPASF_LivenessThreshold) livenessThreshold;

/*!
 * @brief                          获取RGB活体阈值
 * @param livenessThreshold                                      活体阈值
 * @return                          成功返回MOK，否则返回失败code
 */
- (MRESULT)getLivenessThreshold:(LPASF_LivenessThreshold)livenessThreshold;

/*!
 * @brief                   获取RGB活体结果
 * @param livenessScore     检测到的活体结果
 * @return                  成功返回MOK，否则返回失败code
 */
- (MRESULT)getLiveness:(LPASF_LivenessInfo)livenessScore;

/*!
 * @brief                          批量注册人脸特征信息
 * @param width                                      图像宽
 * @param height                                                图像高度
 * @param format                                                图像格式
 * @param data                                                图像数据
 * @param faceInfo                                                单个人脸信息
 * @param iAction                                                当前的动作
 * @param iReset                                                是否复位交互式动作检测
 * @param livenessResult                                                活体检测结果
 * @return                          成功返回MOK，否则返回失败code
 */
- (MRESULT)detectLivenessInteractiveWithWidth:(MInt32) width
                                       height:(MInt32)height
                                       format:(MInt32)format
                                         data:(MUInt8*)data
                               singleFaceInfo:(LPASF_SingleFaceInfo)faceInfo
                                       action:(MInt32) iAction
                                     resetOpt:(MInt32) iReset
                               livenessResult:(LPASF_LivenessResult)livenessResult;


/*!
 * @brief                          炫光活体检测
 * @param width                                      图像宽
 * @param height                                                图像高度
 * @param format                                                图像格式
 * @param data                                                图像数据
 * @param faceInfo                                                单个人脸信息
 * @param iMode                                                炫光颜色顺序模式
 * @param currentFlashColor                                                当前炫光的颜色
 * @param iReset                                                是否复位本轮炫光活体检测
 * @param livenessResult                                                活体检测结果
 * @return                          成功返回MOK，否则返回失败code
 */
- (MRESULT)detectLivenessGlareWithWidth:(MInt32) width
                                       height:(MInt32)height
                                       format:(MInt32)format
                                         data:(MUInt8*)data
                               singleFaceInfo:(LPASF_SingleFaceInfo)faceInfo
                                flashSequence:(MInt32) iMode
                                        color:(MInt32) currentFlashColor
                                     resetOpt:(MInt32) iReset
                         livenessResult:(LPASF_LivenessResult)livenessResult;

@end




