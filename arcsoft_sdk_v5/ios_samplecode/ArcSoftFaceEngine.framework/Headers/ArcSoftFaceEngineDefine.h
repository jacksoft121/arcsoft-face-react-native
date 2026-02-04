/*******************************************************************************
 Copyright(c) ArcSoft, All right reserved.
 
 This file is ArcSoft's property. It contains ArcSoft's trade secret, proprietary
 and confidential information.
 
 The information and code contained in this file is only for authorized ArcSoft
 employees to design, create, modify, or review.
 
 DO NOT DISTRIBUTE, DO NOT DUPLICATE OR TRANSMIT IN ANY FORM WITHOUT PROPER
 AUTHORIZATION.
 
 If you are not an intended recipient of this file, you must not copy,
 distribute, modify, or take any action in reliance on it.
 
 If you have received this file in error, please immediately notify ArcSoft and
 permanently delete the original and any copy of any file and any printout thereof.
 *******************************************************************************/

/*!
 @header ArcSoftFaceEngineDefine.h
 @brief 结构体头文件
 */
#import <ArcSoftFaceEngine/amcomdef.h>
#import <ArcSoftFaceEngine/merror.h>
#import <ArcSoftFaceEngine/asvloffscreen.h>
#ifndef ArcSoftFaceEngineDefine_h
#define ArcSoftFaceEngineDefine_h


#define ASF_NONE                     0x00000000    //无属性
#define ASF_FACE_DETECT              0x00000001    //此处detect可以是tracking或者detection两个引擎之一，具体的选择由detect mode 确定
#define ASF_FACERECOGNITION          0x00000004    //人脸特征
#define ASF_AGE                      0x00000008    //年龄
#define ASF_GENDER                   0x00000010    //性别
#define ASF_LIVENESS                 0x00000080    //RGB活体
#define ASF_LIVENESS_SCREENFLASH     0x00002000     //交互式炫光活体


#define ASF_MAX_DETECTFACENUM   10          //该版本最大支持同时检测10张人脸

//检测模式
typedef enum {
    ASF_DETECT_MODE_VIDEO = 0x00000000,        //Video模式，一般用于多帧连续检测
    ASF_DETECT_MODE_IMAGE = 0xFFFFFFFF        //Image模式，一般用于静态图的单次检测
}ASF_DetectMode;


//检测时候人脸角度的优先级，在文档中初始化接口中有图示说明，请参考
typedef enum {
    ASF_OP_0_ONLY = 0x1,        // 常规预览下正方向
    ASF_OP_90_ONLY = 0x2,        // 基于0°逆时针旋转90°的方向
    ASF_OP_270_ONLY = 0x3,        // 基于0°逆时针旋转270°的方向
    ASF_OP_180_ONLY = 0x4,        // 基于0°旋转180°的方向（逆时针、顺时针效果一样）
    ASF_OP_ALL_OUT = 0x5        // 全角度
}ASF_OrientPriority;

//orientation 角度，逆时针方向
typedef enum {
    ASF_OC_0 = 0x1,            // 0 degree
    ASF_OC_90 = 0x2,        // 90 degree
    ASF_OC_270 = 0x3,        // 270 degree
    ASF_OC_180 = 0x4           // 180 degree
}ASF_OrientCode;

//检测模型
typedef enum  {
    ASF_DETECT_MODEL_RGB = 0x1    //RGB图像检测模型
    //预留扩展其他检测模型
}ASF_DetectModel;

//人脸比对可选的模型
typedef enum {
    ASF_LIFE_PHOTO = 0x1,    //用于生活照之间的特征比对，推荐阈值0.80
    ASF_ID_PHOTO = 0x2        //用于证件照或生活照与证件照之间的特征比对，推荐阈值0.80
}ASF_CompareModel;

//炫光颜色顺序
typedef enum {
ASF_WRGB = 0x0,        /* 白红绿蓝 */
ASF_WRGP = 0x1,        /* 白红绿粉 */
ASF_WRGY = 0x2,        /* 白红绿黄 */
}ASF_ColorCode;

typedef enum {
    ASF_ACTION_TYPE_U = 0,       //未知
    ASF_ACTION_TYPE_EB = 1,      //眨眼
    ASF_ACTION_TYPE_MO = 2,      //张嘴
    ASF_ACTION_TYPE_HL = 3,      //左摆头
    ASF_ACTION_TYPE_HR = 4,      //右摆头
}ASF_ActionType;

typedef enum
{
    ASF_COLOR_WHITE,               //白色
    ASF_COLOR_RED,                 //红色
    ASF_COLOR_GREEN,               //绿色
    ASF_COLOR_BLUE,                //蓝色
    ASF_COLOR_PINK,                //粉色
    ASF_COLOR_YELLOW,              //黄色
    ASF_COLOR_BLACK                //黑色
}ASF_FlashColor;
//版本信息
typedef struct
{
    MPChar Version;                // 版本号
    MPChar BuildDate;            // 构建日期
    MPChar CopyRight;            // Copyright
}ASF_VERSION, *LPASF_VERSION;

//图像数据
typedef LPASVLOFFSCREEN LPASF_ImageData;

//3D角度信息
typedef struct
{
    MFloat* roll;
    MFloat* yaw;
    MFloat* pitch;
}ASF_Face3DAngleInfo, *LPASF_Face3DAngleInfo;

//人脸信息
typedef struct{
    MPVoid        data;        // 人脸信息
    MInt32        dataSize;    // 人脸信息长度
} ASF_FaceDataInfo, *LPASF_FaceDataInfo;

//单人脸信息
typedef struct {
    MRECT        faceRect;                // 人脸框信息
    MInt32        faceOrient;                // 输入图像的角度，可以参考 ArcFaceCompare_OrientCode
    ASF_FaceDataInfo faceDataInfo;      // 单张人脸信息
} ASF_SingleFaceInfo, *LPASF_SingleFaceInfo;

//多人脸框信息
typedef struct{
    MInt32                  faceNum;                // 检测到的人脸个数
    MRECT*                  faceRect;               // 人脸框信息
    MInt32*                 faceOrient;             // 输入图像的角度，可以参考 ArcFace_OrientCode .
    MInt32*                 faceID;                 // face ID
    LPASF_FaceDataInfo      faceDataInfoList;        // 人脸检测信息
    MInt32*                 faceIsWithinBoundary;   // 人脸是否在边界内 0 人脸溢出；1 人脸在图像边界内
    MRECT*                  foreheadRect;           // 人脸额头区域
    ASF_Face3DAngleInfo     face3DAngleInfo;        // 人脸3D角度
}ASF_MultiFaceInfo, *LPASF_MultiFaceInfo;



typedef struct
{
    MInt32 iRes;   //活体检测结果
    MInt32 iNum;   //交互式活体次数
}ASF_LivenessResult, *LPASF_LivenessResult;


//******************************** 人脸识别相关 *********************************************
typedef struct {
    MByte*        feature;        // 人脸特征信息
    MInt32        featureSize;    // 人脸特征信息长度
}ASF_FaceFeature, *LPASF_FaceFeature;

typedef struct{
    MInt32      searchId;       // 唯一标识符
    LPASF_FaceFeature feature;  // 人脸特征值
    MPCChar     tag;            // 备注
}ASF_FaceFeatureInfo, *LPASF_FaceFeatureInfo;

typedef struct
{
    MFloat     confidenceLevel;
    ASF_FaceFeatureInfo stFaceFeatureInfo;
}ASF_FaceFeatureSearchResult,*LPASF_FaceFeatureSearchResult;


typedef struct {
    MInt32*    ageArray;                // "0" 代表不确定，大于0的数值代表检测出来的年龄结果
    MInt32    num;                    // 检测的人脸个数
}ASF_AgeInfo, *LPASF_AgeInfo;


typedef struct {
    MInt32*    genderArray;            // "0" 表示 男性, "1" 表示 女性, "-1" 表示不确定
    MInt32    num;                    // 检测的人脸个数
}ASF_GenderInfo, *LPASF_GenderInfo;

typedef struct {
    MFloat        thresholdmodel_BGR;
}ASF_LivenessThreshold, *LPASF_LivenessThreshold;

typedef struct {
    MInt32*    isLive;            // [out] 判断是否真人， 0：非真人；
                            // 1：真人；
                            // -1：不确定；
                            // -2:传入人脸数>1；
                            // -3: 人脸过小
                            // -4: 角度过大
                            // -5: 人脸超出边界

    MInt32 num;
}ASF_LivenessInfo, *LPASF_LivenessInfo;



#endif
