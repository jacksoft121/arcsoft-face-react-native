#import "ArcSoftFaceManager.h"

/** ===== ArcSoft 官方头文件 ===== */
#import "arcsoft_face_engine.h"
#import "asvloffscreen.h"

@implementation ArcSoftFaceManager {
    MHandle _engine;
}

+ (instancetype)shared {
    static ArcSoftFaceManager *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        m = [[ArcSoftFaceManager alloc] init];
    });
    return m;
}

#pragma mark - SDK 激活（官方 Demo）

- (int)activateWithAppId:(NSString *)appId
                  sdkKey:(NSString *)sdkKey {

    return ASFOnlineActivation(
        appId.UTF8String,
        sdkKey.UTF8String
    );
}

#pragma mark - 初始化引擎

- (int)initEngine {
    if (_engine) return 0;

    ASFInitEngineParam param;
    memset(&param, 0, sizeof(param));

    param.detectMode = ASF_DETECT_MODE_IMAGE;
    param.detectFaceOrientPriority = ASF_OP_0_ONLY;
    param.detectFaceScaleVal = 16;
    param.detectFaceMaxNum = 10;
    param.combinedMask =
        ASF_FACE_DETECT |
        ASF_FACE_RECOGNITION |
        ASF_LIVENESS;

    return ASFInitEngine(&param, &_engine);
}

#pragma mark - NV21 → ASVLOFFSCREEN

- (ASVLOFFSCREEN)offscreenFromNV21:(NSData *)nv21
                             width:(int)width
                            height:(int)height {

    ASVLOFFSCREEN off;
    memset(&off, 0, sizeof(off));

    off.u32PixelArrayFormat = ASVL_PAF_NV21;
    off.i32Width = width;
    off.i32Height = height;

    off.ppu8Plane[0] = (uint8_t *)nv21.bytes;
    off.pi32Pitch[0] = width;

    off.ppu8Plane[1] = off.ppu8Plane[0] + width * height;
    off.pi32Pitch[1] = width;

    return off;
}

#pragma mark - 人脸检测

- (NSArray *)detectFacesFromNV21:(NSData *)nv21
                            width:(int)width
                           height:(int)height {

    ASVLOFFSCREEN off = [self offscreenFromNV21:nv21 width:width height:height];

    ASFDetectFaces(_engine, &off);

    ASF_MultiFaceInfo info;
    ASFGetDetectedFaces(_engine, &info);

    NSMutableArray *arr = [NSMutableArray array];

    for (int i = 0; i < info.faceNum; i++) {
        NSDictionary *d = @{
            @"left": @(info.faceRect[i].left),
            @"top": @(info.faceRect[i].top),
            @"right": @(info.faceRect[i].right),
            @"bottom": @(info.faceRect[i].bottom),
            @"orient": @(info.faceOrient[i])
        };
        [arr addObject:d];
    }

    return arr;
}

#pragma mark - 特征提取

- (NSDictionary *)extractFeatureFromNV21:(NSData *)nv21
                                   width:(int)width
                                  height:(int)height
                               faceIndex:(int)faceIndex {

    ASVLOFFSCREEN off = [self offscreenFromNV21:nv21 width:width height:height];

    ASFDetectFaces(_engine, &off);

    ASF_MultiFaceInfo faces;
    ASFGetDetectedFaces(_engine, &faces);

    ASF_FaceFeature feature;
    memset(&feature, 0, sizeof(feature));

    ASFExtractFaceFeature(
        _engine,
        &off,
        &faces.faceRect[faceIndex],
        faces.faceOrient[faceIndex],
        &feature
    );

    NSData *feat = [NSData dataWithBytes:feature.feature
                                  length:feature.featureSize];

    return @{
        @"feature": [feat base64EncodedStringWithOptions:0],
        @"size": @(feature.featureSize)
    };
}

#pragma mark - 人脸比对

- (float)compareFeature:(NSData *)f1 with:(NSData *)f2 {
    ASF_FaceFeature a, b;
    a.feature = (uint8_t *)f1.bytes;
    a.featureSize = (int)f1.length;

    b.feature = (uint8_t *)f2.bytes;
    b.featureSize = (int)f2.length;

    float score = 0;
    ASFFaceFeatureCompare(_engine, &a, &b, &score);
    return score;
}

#pragma mark - 活体检测

- (NSArray *)livenessFromNV21:(NSData *)nv21
                        width:(int)width
                       height:(int)height
                    faceInfos:(NSArray *)faces {

    ASVLOFFSCREEN off = [self offscreenFromNV21:nv21 width:width height:height];

    ASFProcess(_engine, &off, ASF_LIVENESS);

    ASF_LivenessInfo live;
    ASFGetLivenessScore(_engine, &live);

    return @[@(live.isLive)];
}

#pragma mark - 释放

- (void)releaseEngine {
    if (_engine) {
        ASFUninitEngine(_engine);
        _engine = NULL;
    }
}

@end
