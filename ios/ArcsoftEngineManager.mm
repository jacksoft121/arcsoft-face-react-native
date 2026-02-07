#import "ArcsoftEngineManager.h"
#import "PixelBufferUtils.h" // For ASVLOFFSCREEN conversion

/// 逐行对照官方 iOS Demo：
/// - engine/ASFVideoProcessor.m
/// - engine/ASFImageProcessor.m
/// - util/Utility.m

@interface ArcsoftEngineManager ()
@property(nonatomic, readwrite) BOOL inited;
@property(nonatomic, strong, readwrite) ArcSoftFaceEngine *engine;
@property(nonatomic, assign) int combinedMask;
@property(nonatomic, strong) NSArray<NSDictionary *> *lastFace3DAngles;
@property(nonatomic, strong) NSArray<NSNumber *> *lastAges;
@property(nonatomic, strong) NSArray<NSNumber *> *lastGenders;
@property(nonatomic, strong) NSArray<NSNumber *> *lastLiveness;

// Face DB
// userId (String) -> searchId (Int)
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *userToSearchId;
// searchId (Int) -> userId (String)
@property(nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *searchIdToUser;
// 自增 ID 计数器
@property(nonatomic, assign) int nextSearchId;

@end

@implementation ArcsoftEngineManager

+ (instancetype)sharedInstance {
    static ArcsoftEngineManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ArcsoftEngineManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
  if (self = [super init]) {
    _engine = [[ArcSoftFaceEngine alloc] init];
    _inited = NO;
    _combinedMask = 0;
    _lastFace3DAngles = @[];
    _lastAges = @[];
    _lastGenders = @[];
    _lastLiveness = @[];

    // DB
    _userToSearchId = [NSMutableDictionary dictionary];
    _searchIdToUser = [NSMutableDictionary dictionary];
    _nextSearchId = 1000; // 从 1000 开始，避免与系统保留 ID 冲突

    NSLog(@"[ArcsoftEngineManager] init: engine=%@", _engine);
  }
  return self;
}

/**
 * 激活 SDK
 */
- (int)activateWithAppId:(NSString *)appId
                 sdkKey:(NSString *)sdkKey
              activeKey:(NSString *)activeKey {
  NSLog(@"[ArcsoftEngineManager] activateWithAppId: engine=%@", self.engine);

  if (!self.engine) {
      NSLog(@"[ArcsoftEngineManager] Error: engine is nil");
      return -1;
  }
  return [self.engine activeWithAppId:appId SDKKey:sdkKey];
}

/**
 * 获取激活文件信息
 */
- (nullable NSDictionary *)getActiveFileInfo {
    if (!self.engine) return nil;

    ArcSoftActiveInfo *activeInfo = [[ArcSoftActiveInfo alloc] init];
    MRESULT result = [self.engine getActiveFileInfo:activeInfo];

    if (result != MOK) {
        NSLog(@"[ArcsoftEngineManager] getActiveFileInfo failed: %ld", (long)result);
        return nil;
    }

    return @{
        @"appId": activeInfo.appId ?: @"",
        @"sdkKey": activeInfo.sdkKey ?: @"",
        @"platform": activeInfo.platform ?: @"",
        @"sdkVersion": activeInfo.sdkVersion ?: @"",
        @"fileVersion": activeInfo.fileVersion ?: @"",
        @"expireTime": activeInfo.endTime ?: @"",
        // deviceFingerprint is not available in ArcSoftActiveInfo for iOS
        @"deviceFingerprint": @""
    };
}

/**
 * 初始化引擎
 */
- (int)initEngineWithDetectMode:(ASF_DetectMode)detectMode
                 orientPriority:(ASF_OrientPriority)orientPriority
                     maxFaceNum:(int)maxFaceNum
                   combinedMask:(int)combinedMask {
  NSLog(@"[ArcsoftEngineManager] initEngineWithDetectMode: mask=%d", combinedMask);
  self.combinedMask = combinedMask;
  int code = [self.engine initFaceEngineWithDetectMode:detectMode
                             orientPriority:orientPriority
                                 maxFaceNum:maxFaceNum
                               combinedMask:combinedMask];
  self.inited = (code == MOK);
  NSLog(@"[ArcsoftEngineManager] initEngine result: %d", code);
  return code;
}

/**
 * 销毁引擎
 */
- (void)uninit {
  if (self.inited) {
    [self.engine unInitFaceEngine];
    self.inited = NO;

    // Clear DB maps
    [self.userToSearchId removeAllObjects];
    [self.searchIdToUser removeAllObjects];
  }
}

#pragma mark - Image Processing Helpers

// Helper to convert UIImage to ASVLOFFSCREEN
- (ASVLOFFSCREEN)offscreenFromImage:(UIImage *)image {
    CGImageRef cgImage = image.CGImage;
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = width * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    // Explicitly cast malloc's void* to MUInt8*
    MUInt8 *data = (MUInt8 *)malloc(bytesPerRow * height);

    CGContextRef context = CGBitmapContextCreate(data, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);

    ASVLOFFSCREEN offscreen = {0};
    offscreen.u32PixelArrayFormat = ASVL_PAF_RGB32_B8G8R8A8; // Assuming BGRA
    offscreen.i32Width = (int)width;
    offscreen.i32Height = (int)height;
    offscreen.ppu8Plane[0] = data;
    offscreen.pi32Pitch[0] = (int)bytesPerRow;

    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    return offscreen;
}

- (void)freeOffscreen:(ASVLOFFSCREEN *)offscreen {
    if (offscreen && offscreen->ppu8Plane[0]) {
        free(offscreen->ppu8Plane[0]);
    }
}

#pragma mark - Core Methods

/**
 * 处理人脸属性（年龄、性别、活体等）
 */
- (void)processFaces:(ASVLOFFSCREEN *)offscreen faces:(ASF_MultiFaceInfo *)faces {
    // Cache 3D angles
    NSMutableArray *angles = [NSMutableArray arrayWithCapacity:faces->faceNum];
    if (faces->face3DAngleInfo.yaw && faces->face3DAngleInfo.pitch && faces->face3DAngleInfo.roll) {
        for (int i = 0; i < faces->faceNum; i++) {
            [angles addObject:@{
                @"yaw": @(faces->face3DAngleInfo.yaw[i]),
                @"pitch": @(faces->face3DAngleInfo.pitch[i]),
                @"roll": @(faces->face3DAngleInfo.roll[i]),
            }];
        }
    }
    self.lastFace3DAngles = angles;

    // Process Age, Gender, Liveness if requested
    int processMask = self.combinedMask & (ASF_AGE | ASF_GENDER | ASF_LIVENESS);
    if (processMask != 0 && faces->faceNum > 0) {
        [self.engine processWithWidth:offscreen->i32Width
                               height:offscreen->i32Height
                                 data:offscreen->ppu8Plane[0]
                               format:offscreen->u32PixelArrayFormat
                              faceRes:faces
                                 mask:processMask];

        // Cache results
        ASF_AgeInfo ageInfo = {0};
        [self.engine getAge:&ageInfo];
        NSMutableArray *ages = [NSMutableArray arrayWithCapacity:ageInfo.num];
        for (int i=0; i<ageInfo.num; i++) [ages addObject:@(ageInfo.ageArray[i])];
        self.lastAges = ages;

        ASF_GenderInfo genderInfo = {0};
        [self.engine getGender:&genderInfo];
        NSMutableArray *genders = [NSMutableArray arrayWithCapacity:genderInfo.num];
        for (int i=0; i<genderInfo.num; i++) [genders addObject:@(genderInfo.genderArray[i])];
        self.lastGenders = genders;

        ASF_LivenessInfo livenessInfo = {0};
        [self.engine getLiveness:&livenessInfo];
        NSMutableArray *liveness = [NSMutableArray arrayWithCapacity:livenessInfo.num];
        for (int i=0; i<livenessInfo.num; i++) [liveness addObject:@(livenessInfo.isLive[i])];
        self.lastLiveness = liveness;
    } else {
        self.lastAges = @[];
        self.lastGenders = @[];
        self.lastLiveness = @[];
    }
}

/**
 * 人脸检测 (视频流)
 */
- (NSArray<NSDictionary *> *)detectFaces:(ASVLOFFSCREEN *)offscreen {
  if (!self.inited || offscreen == NULL) return @[];

  ASF_MultiFaceInfo faces = {0};
  MRESULT result = [self.engine detectFacesWithWidth:offscreen->i32Width
                                              height:offscreen->i32Height
                                                data:offscreen->ppu8Plane[0]
                                              format:offscreen->u32PixelArrayFormat
                                             faceRes:&faces];

  if (result != MOK) return @[];

  [self processFaces:offscreen faces:&faces];

  NSMutableArray *out = [NSMutableArray arrayWithCapacity:faces.faceNum];
  for (int i = 0; i < faces.faceNum; i++) {
    MRECT r = faces.faceRect[i];
    [out addObject:@{
      @"rect": @{ @"left": @(r.left), @"top": @(r.top), @"right": @(r.right), @"bottom": @(r.bottom) },
      @"orient": @(faces.faceOrient[i]),
    }];
  }
  return out;
}

/**
 * 人脸检测 (图片)
 */
- (NSArray<NSDictionary *> *)detectFacesFromImage:(UIImage *)image {
    if (!self.inited || !image) return @[];
    ASVLOFFSCREEN offscreen = [self offscreenFromImage:image];
    NSArray<NSDictionary *> *faces = [self detectFaces:&offscreen];
    [self freeOffscreen:&offscreen];
    return faces;
}

/**
 * 提取人脸特征 (视频流)
 */
- (NSString *)extractFeature:(ASVLOFFSCREEN *)offscreen
                    faceRect:(MRECT)rect
                      orient:(int)orient {
  if (!self.inited || offscreen == NULL) return nil;

  ASF_SingleFaceInfo info = {0};
  info.faceRect = rect;
  info.faceOrient = orient;

  ASF_FaceFeature feature = {0};
  MRESULT result = [self.engine extractFaceFeatureWithWidth:offscreen->i32Width
                                                     height:offscreen->i32Height
                                                       data:offscreen->ppu8Plane[0]
                                                     format:offscreen->u32PixelArrayFormat
                                                   faceInfo:&info
                                                    feature:&feature];

  if (result != MOK || feature.featureSize <= 0 || feature.feature == NULL) return nil;

  NSData *data = [NSData dataWithBytes:feature.feature length:(NSUInteger)feature.featureSize];
  return [data base64EncodedStringWithOptions:0];
}

/**
 * 提取人脸特征 (图片)
 */
- (nullable NSString *)extractFeatureFromImage:(UIImage *)image
                                      faceInfo:(NSDictionary *)faceInfo {
    if (!self.inited || !image || !faceInfo) return nil;

    ASVLOFFSCREEN offscreen = [self offscreenFromImage:image];

    NSDictionary *rectDict = faceInfo[@"rect"];
    MRECT rect = {
        [rectDict[@"left"] intValue], [rectDict[@"top"] intValue],
        [rectDict[@"right"] intValue], [rectDict[@"bottom"] intValue]
    };
    int orient = [faceInfo[@"orient"] intValue];

    NSString *feature = [self extractFeature:&offscreen faceRect:rect orient:orient];

    [self freeOffscreen:&offscreen];
    return feature;
}

/**
 * 特征比对
 */
- (float)compareFeature1:(NSData *)f1 feature2:(NSData *)f2 {
  if (!self.inited || !f1 || !f2) return 0.f;

  ASF_FaceFeature ff1 = {0};
  ff1.featureSize = (int)f1.length;
  ff1.feature = (MByte *)f1.bytes;

  ASF_FaceFeature ff2 = {0};
  ff2.featureSize = (int)f2.length;
  ff2.feature = (MByte *)f2.bytes;

  MFloat confidenceLevel = 0.0;
  [self.engine compareFaceWithFeature:&ff1 feature2:&ff2 confidenceLevel:&confidenceLevel];
  return confidenceLevel;
}

- (NSArray<NSNumber *> *)getAges { return self.lastAges ?: @[]; }
- (NSArray<NSNumber *> *)getGenders { return self.lastGenders ?: @[]; }
- (NSArray<NSDictionary *> *)getFace3DAngles { return self.lastFace3DAngles ?: @[]; }
- (NSArray<NSNumber *> *)getLiveness { return self.lastLiveness ?: @[]; }

// =========================
// Face DB (in-engine DB)
// =========================

/**
 * 注册/更新人脸特征
 */
- (BOOL)faceDBAddOrUpdate:(NSString *)userId featureData:(NSData *)featureData {
    if (!self.inited || !userId.length || !featureData.length) return NO;

    // 1. 检查是否已存在
    NSNumber *existingId = self.userToSearchId[userId];
    if (existingId) {
        // 如果已存在，先移除旧的
        [self faceDBRemove:userId];
    }

    // 2. 分配新 ID
    int searchId = self.nextSearchId++;

    // 3. 构造注册信息
    ASF_FaceFeature featureStruct = {0};
    featureStruct.feature = (MByte *)featureData.bytes;
    featureStruct.featureSize = (MInt32)featureData.length;

    ASF_FaceFeatureInfo info = {0};
    info.searchId = searchId;
    info.feature = &featureStruct;
    info.tag = "";

    // 4. 调用引擎注册
    MRESULT mr = [self.engine registerSingleFaceFeatureWithFeatureInfo:&info];
    if (mr == MOK) {
        // 5. 更新映射
        self.userToSearchId[userId] = @(searchId);
        self.searchIdToUser[@(searchId)] = userId;
        return YES;
    }

    return NO;
}

/**
 * 移除人脸特征
 */
- (BOOL)faceDBRemove:(NSString *)userId {
    if (!self.inited || !userId.length) return NO;

    NSNumber *searchId = self.userToSearchId[userId];
    if (!searchId) return NO;

    MRESULT mr = [self.engine removeFaceFeatureWithSearchId:[searchId intValue]];

    // 无论引擎返回成功与否，都清理本地映射
    [self.userToSearchId removeObjectForKey:userId];
    [self.searchIdToUser removeObjectForKey:searchId];

    return (mr == MOK);
}

/**
 * 清空人脸库
 */
- (BOOL)faceDBClear {
    if (!self.inited) return NO;

    MRESULT mr = [self.engine clearAllFaceFeature];

    [self.userToSearchId removeAllObjects];
    [self.searchIdToUser removeAllObjects];
    self.nextSearchId = 1000;

    return (mr == MOK);
}

/**
 * 获取人脸库数量
 */
- (NSInteger)faceDBCount {
    if (!self.inited) return 0;

    MInt32 count = 0;
    MRESULT mr = [self.engine getFaceCount:&count];
    if (mr == MOK) {
        return (NSInteger)count;
    }
    return 0;
}

/**
 * 搜索人脸 (1:N)
 */
- (NSDictionary * _Nullable)faceDBSearchTop1:(NSData *)featureData threshold:(float)threshold {
    if (!self.inited || !featureData.length) return nil;

    ASF_FaceFeature feature = {0};
    feature.feature = (MByte *)featureData.bytes;
    feature.featureSize = (MInt32)featureData.length;

    ASF_FaceFeatureInfo resultInfo = {0};
    MFloat confidence = 0.0f;

    // 1:N 搜索
    MRESULT mr = [self.engine searchFaceFeatureWithFeature:&feature
                                         compareModel:ASF_LIFE_PHOTO
                                           similarity:&confidence
                                      faceFeatureInfo:&resultInfo];

    if (mr == MOK && confidence >= threshold) {
        // 反查 userId
        NSString *userId = self.searchIdToUser[@(resultInfo.searchId)];
        if (userId) {
            return @{
                @"id": userId,
                @"score": @(confidence)
            };
        }
    }

    return nil;
}

@end
