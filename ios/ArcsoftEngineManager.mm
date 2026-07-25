#import "ArcsoftEngineManager.h"
#import "PixelBufferUtils.h" // For ASVLOFFSCREEN conversion
#import "FaceDB.h" // Import FaceDB

/// 逐行对照官方 iOS Demo：
/// - engine/ASFVideoProcessor.m
/// - engine/ASFImageProcessor.m
/// - util/Utility.m

@interface ArcsoftEngineManager ()
@property(nonatomic, readwrite) BOOL inited;
@property(nonatomic, strong, readwrite) ArcSoftFaceEngine *engine;
/// IMAGE+识别引擎与 VIDEO 跟踪引擎分离，避免特征搜索阻塞相机框更新。
@property(nonatomic, strong) ArcSoftFaceEngine *recognitionEngine;
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

// 优化策略缓存
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *processedFaceIds; // faceId -> userId
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *faceRetryCounts; // faceId -> retry count
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *faceScores; // faceId -> score
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *faceFeatures; // faceId -> featureBase64
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *faceLastSeenAt;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *faceLastAttemptAt;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *faceRecognitionGenerations;
@property (nonatomic, strong) NSObject *faceStateLock;
@property (nonatomic, assign) NSInteger faceStateGeneration;

- (void)clearFaceStateLocked:(NSNumber *)faceId;
- (NSArray<NSDictionary *> *)detectFaces:(ASVLOFFSCREEN *)offscreen
                             usingEngine:(ArcSoftFaceEngine *)targetEngine
                       processAttributes:(BOOL)processAttributes;

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
    _recognitionEngine = [[ArcSoftFaceEngine alloc] init];
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

    // Cache
    _processedFaceIds = [NSMutableDictionary dictionary];
    _faceRetryCounts = [NSMutableDictionary dictionary];
    _faceScores = [NSMutableDictionary dictionary];
    _faceFeatures = [NSMutableDictionary dictionary];
    _faceLastSeenAt = [NSMutableDictionary dictionary];
    _faceLastAttemptAt = [NSMutableDictionary dictionary];
    _faceRecognitionGenerations = [NSMutableDictionary dictionary];
    _faceStateLock = [[NSObject alloc] init];
    _faceStateGeneration = 1;

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
  @synchronized (self) {
      NSLog(@"[ArcsoftEngineManager] activateWithAppId: engine=%@", self.engine);

      if (!self.engine) {
          NSLog(@"[ArcsoftEngineManager] Error: engine is nil");
          return -1;
      }
      return [self.engine activeWithAppId:appId SDKKey:sdkKey];
  }
}

/**
 * 获取激活文件信息
 */
- (nullable NSDictionary *)getActiveFileInfo {
    @synchronized (self) {
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
            @"sdkType": activeInfo.sdkType ?: @"",
            @"sdkVersion": activeInfo.sdkVersion ?: @"",
            @"fileVersion": activeInfo.fileVersion ?: @"",
            @"startTime": activeInfo.startTime ?: @"",
            @"endTime": activeInfo.endTime ?: @"",
            // deviceFingerprint is not available in ArcSoftActiveInfo for iOS
            @"deviceFingerprint": @""
        };
    }
}

/**
 * 初始化引擎
 */
- (int)initEngineWithDetectMode:(ASF_DetectMode)detectMode
                 orientPriority:(ASF_OrientPriority)orientPriority
                     maxFaceNum:(int)maxFaceNum
                   combinedMask:(int)combinedMask {
  @synchronized (self) {
      if (self.inited) {
          return MOK;
      }

      NSLog(@"[ArcsoftEngineManager] init split engines: mode=%u, mask=%d", (unsigned int)detectMode, combinedMask);
      int trackingMask = (combinedMask | ASF_FACE_DETECT) & ~ASF_FACERECOGNITION;
      // 官方门禁方案的附加句柄仅加载识别能力，避免重复加载检测和属性模型。
      int recognitionMask = ASF_FACERECOGNITION;
      self.combinedMask = trackingMask;

      // 相机预览固定使用 VIDEO 跟踪；VisionCamera 已物理旋转帧，所以保持单角度。
      MRESULT trackingCode = [self.engine initFaceEngineWithDetectMode:ASF_DETECT_MODE_VIDEO
                                                       orientPriority:orientPriority
                                                           maxFaceNum:maxFaceNum
                                                         combinedMask:trackingMask];
      if (trackingCode != MOK) {
          NSLog(@"[ArcsoftEngineManager] tracking engine init failed: %ld", (long)trackingCode);
          return (int)trackingCode;
      }

      // 特征提取和 1:N 搜索使用独立 IMAGE 识别引擎。
      MRESULT recognitionCode = [self.recognitionEngine initFaceEngineWithDetectMode:ASF_DETECT_MODE_IMAGE
                                                                      orientPriority:orientPriority
                                                                          maxFaceNum:maxFaceNum
                                                                        combinedMask:recognitionMask];
      if (recognitionCode != MOK) {
          NSLog(@"[ArcsoftEngineManager] recognition engine init failed: %ld", (long)recognitionCode);
          [self.engine unInitFaceEngine];
          return (int)recognitionCode;
      }

      self.inited = YES;
      [self loadFacesFromDB];
      NSLog(@"[ArcsoftEngineManager] split engines initialized");
      return MOK;
  }
}

- (void)loadFacesFromDB {
    NSArray<FaceRecord *> *faces = [[FaceDB sharedInstance] getAllFaces];

    // Clear current maps
    [self.userToSearchId removeAllObjects];
    [self.searchIdToUser removeAllObjects];
    self.nextSearchId = 1000;

    for (FaceRecord *record in faces) {
        int searchId = self.nextSearchId++;

        ASF_FaceFeature featureStruct = {0};
        featureStruct.feature = (MByte *)record.featureData.bytes;
        featureStruct.featureSize = (MInt32)record.featureData.length;

        ASF_FaceFeatureInfo info = {0};
        info.searchId = searchId;
        info.feature = &featureStruct;
        info.tag = "";

        MRESULT mr = [self.recognitionEngine registerSingleFaceFeatureWithFeatureInfo:&info];
        if (mr == MOK) {
            self.userToSearchId[record.userId] = @(searchId);
            self.searchIdToUser[@(searchId)] = record.userId;
        } else {
            NSLog(@"[ArcsoftEngineManager] Failed to register face from DB: %@, code=%ld", record.userId, (long)mr);
        }
    }
    NSLog(@"[ArcsoftEngineManager] Loaded %lu faces from DB", (unsigned long)self.userToSearchId.count);
}

/**
 * 销毁引擎
 */
- (void)uninit {
  @synchronized (self) {
      if (self.inited) {
        // 锁顺序固定为 VIDEO 后 IMAGE，等待正在处理的跟踪/识别调用结束。
        @synchronized (self.engine) {
          @synchronized (self.recognitionEngine) {
            [self.engine unInitFaceEngine];
            [self.recognitionEngine unInitFaceEngine];
            self.inited = NO;

            [self.userToSearchId removeAllObjects];
            [self.searchIdToUser removeAllObjects];
            [self clearCache];
          }
        }
      }
  }
}

#pragma mark - Cache Management

- (void)clearCache {
    @synchronized (self.faceStateLock) {
        self.faceStateGeneration += 1;
        [self.processedFaceIds removeAllObjects];
        [self.faceRetryCounts removeAllObjects];
        [self.faceScores removeAllObjects];
        [self.faceFeatures removeAllObjects];
        [self.faceLastSeenAt removeAllObjects];
        [self.faceLastAttemptAt removeAllObjects];
        [self.faceRecognitionGenerations removeAllObjects];
        NSLog(@"[ArcsoftEngineManager] Cache cleared");
    }
}

- (BOOL)shouldProcessFace:(int)faceId maxRetryCount:(int)maxRetryCount {
    @synchronized (self.faceStateLock) {
        if (self.processedFaceIds[@(faceId)]) {
            return NO; // 已识别
        }
        int retryCount = [self.faceRetryCounts[@(faceId)] intValue];
        return retryCount < maxRetryCount;
    }
}

- (nullable NSDictionary *)getCachedFaceInfo:(int)faceId {
    @synchronized (self.faceStateLock) {
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        NSString *userId = self.processedFaceIds[@(faceId)];
        if (userId) {
            info[@"userId"] = userId;
            NSNumber *score = self.faceScores[@(faceId)];
            info[@"score"] = score ?: @(1.0);
        }
        NSString *feature = self.faceFeatures[@(faceId)];
        if (feature) {
            info[@"featureBase64"] = feature;
        }
        return info.count > 0 ? info : nil;
    }
}

- (void)updateFaceCache:(int)faceId userId:(nullable NSString *)userId score:(float)score featureBase64:(nullable NSString *)featureBase64 {
    @synchronized (self.faceStateLock) {
        if (userId) {
            self.processedFaceIds[@(faceId)] = userId;
            self.faceScores[@(faceId)] = @(score);
            [self.faceRetryCounts removeObjectForKey:@(faceId)];
        }
        if (featureBase64) {
            self.faceFeatures[@(faceId)] = featureBase64;
        }
    }
}

- (void)updateRetryCount:(int)faceId {
    @synchronized (self.faceStateLock) {
        int count = [self.faceRetryCounts[@(faceId)] intValue];
        self.faceRetryCounts[@(faceId)] = @(count + 1);
    }
}

- (void)cleanUpFaceStates:(NSArray<NSDictionary *> *)currentFaces {
    static NSTimeInterval const faceStateStaleSeconds = 1.5;
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    @synchronized (self.faceStateLock) {
        for (NSDictionary *face in currentFaces) {
            NSNumber *fid = face[@"faceId"];
            if (fid) {
                NSNumber *previousSeenAt = self.faceLastSeenAt[fid];
                if (previousSeenAt && now - previousSeenAt.doubleValue > faceStateStaleSeconds) {
                    [self clearFaceStateLocked:fid];
                }
                self.faceLastSeenAt[fid] = @(now);
            }
        }

        NSMutableArray<NSNumber *> *staleIds = [NSMutableArray array];
        for (NSNumber *fid in self.faceLastSeenAt) {
            if (now - self.faceLastSeenAt[fid].doubleValue > faceStateStaleSeconds) {
                [staleIds addObject:fid];
            }
        }
        for (NSNumber *fid in staleIds) {
            [self clearFaceStateLocked:fid];
        }
    }
}

- (NSInteger)tryBeginFaceRecognition:(int)faceId maxRetryCount:(int)maxRetryCount {
    // 官方 Demo 会在后续预览帧直接重试；120 ms 兼顾移动人脸响应和失败限流。
    static NSTimeInterval const retryIntervalSeconds = 0.12;
    // Demo 的次数限制只作用于一轮提取失败；冷却后重新允许 TO_RETRY，
    // 使远处人脸靠近时能恢复识别，同时避免未注册人脸持续跑满 1:N。
    static NSTimeInterval const retryBurstCooldownSeconds = 0.5;
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    NSNumber *key = @(faceId);
    @synchronized (self.faceStateLock) {
        if (self.processedFaceIds[key]) return -1;
        if (self.faceRecognitionGenerations[key]) return -1;
        NSTimeInterval lastAttemptAt = self.faceLastAttemptAt[key].doubleValue;
        if (self.faceRetryCounts[key].integerValue >= MAX(1, maxRetryCount)) {
            if (now - lastAttemptAt < retryBurstCooldownSeconds) return -1;
            // 对齐 Demo：一轮失败后进入下一轮，而不是永久保留失败状态。
            self.faceRetryCounts[key] = @0;
        }
        if (now - lastAttemptAt < retryIntervalSeconds) return -1;

        NSInteger generation = self.faceStateGeneration;
        self.faceLastAttemptAt[key] = @(now);
        self.faceRecognitionGenerations[key] = @(generation);
        return generation;
    }
}

- (void)completeFaceRecognition:(int)faceId
                     generation:(NSInteger)generation
                          result:(nullable NSDictionary *)result {
    static NSTimeInterval const faceStateStaleSeconds = 1.5;
    NSNumber *key = @(faceId);
    @synchronized (self.faceStateLock) {
        NSNumber *activeGeneration = self.faceRecognitionGenerations[key];
        [self.faceRecognitionGenerations removeObjectForKey:key];
        if (
            !activeGeneration ||
            activeGeneration.integerValue != generation ||
            generation != self.faceStateGeneration
        ) {
            return;
        }

        NSNumber *lastSeenAt = self.faceLastSeenAt[key];
        if (
            !lastSeenAt ||
            NSDate.date.timeIntervalSince1970 - lastSeenAt.doubleValue > faceStateStaleSeconds
        ) {
            [self clearFaceStateLocked:key];
            return;
        }

        NSString *userId = [result[@"id"] isKindOfClass:NSString.class] ? result[@"id"] : nil;
        if (userId.length > 0) {
            self.processedFaceIds[key] = userId;
            self.faceScores[key] = result[@"score"] ?: @(1.0);
            [self.faceRetryCounts removeObjectForKey:key];
            NSString *featureBase64 = [result[@"featureBase64"] isKindOfClass:NSString.class]
              ? result[@"featureBase64"]
              : nil;
            if (featureBase64.length > 0) {
                self.faceFeatures[key] = featureBase64;
            }
            return;
        }
        self.faceRetryCounts[key] = @(self.faceRetryCounts[key].integerValue + 1);
    }
}

- (void)cancelFaceRecognition:(int)faceId generation:(NSInteger)generation {
    NSNumber *key = @(faceId);
    @synchronized (self.faceStateLock) {
        NSNumber *activeGeneration = self.faceRecognitionGenerations[key];
        if (activeGeneration && activeGeneration.integerValue == generation) {
            [self.faceRecognitionGenerations removeObjectForKey:key];
        }
    }
}

/** 仅在持有 faceStateLock 时调用。 */
- (void)clearFaceStateLocked:(NSNumber *)faceId {
    [self.processedFaceIds removeObjectForKey:faceId];
    [self.faceRetryCounts removeObjectForKey:faceId];
    [self.faceScores removeObjectForKey:faceId];
    [self.faceFeatures removeObjectForKey:faceId];
    [self.faceLastSeenAt removeObjectForKey:faceId];
    [self.faceLastAttemptAt removeObjectForKey:faceId];
    [self.faceRecognitionGenerations removeObjectForKey:faceId];
}

#pragma mark - Image Processing Helpers

// Helper to convert UIImage to ASVLOFFSCREEN
// 将 UIImage 转换为 ArcSoft SDK 支持的 NV12 格式
// 解决了直接使用 BGRA 可能导致的颜色空间不支持 (90126) 问题
- (ASVLOFFSCREEN)offscreenFromImage:(UIImage *)image {
    CGImageRef cgImage = image.CGImage;
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);

    // 确保宽度是 4 的倍数 (ArcSoft 要求)
    size_t alignedWidth = (width + 3) & ~3;
    // 确保高度是 2 的倍数 (NV12 要求)
    size_t alignedHeight = (height + 1) & ~1;

    // NSLog(@"[ArcsoftEngineManager] offscreenFromImage: original size=%zux%zu, aligned size=%zux%zu", width, height, alignedWidth, alignedHeight);

    // 1. 创建 BGRA Context
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = alignedWidth * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    // Explicitly cast malloc's void* to MUInt8*
    MUInt8 *bgraData = (MUInt8 *)malloc(bytesPerRow * alignedHeight);

    // 使用对齐后的宽度创建 Context
    // 注意：iOS 上 BGRA 通常使用 kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little
    CGContextRef context = CGBitmapContextCreate(bgraData, alignedWidth, alignedHeight, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);

    // 绘制原始图片
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    // 2. 转换为 NV12 (YUV420SP)
    // ArcSoft SDK 对 NV12 的支持最好，且能避免颜色空间问题
    size_t ySize = alignedWidth * alignedHeight;
    size_t uvSize = alignedWidth * (alignedHeight / 2);
    MUInt8 *nv12Data = (MUInt8 *)malloc(ySize + uvSize);

    // 简单的 BGRA -> NV12 转换 (CPU)
    // 注意：这里假设 BGRA 顺序是 B G R A (Little Endian)
    // Y = 0.299R + 0.587G + 0.114B
    // U = -0.169R - 0.331G + 0.500B + 128
    // V = 0.500R - 0.419G - 0.081B + 128

    MUInt8 *yPtr = nv12Data;
    MUInt8 *uvPtr = nv12Data + ySize;

    for (int y = 0; y < alignedHeight; y++) {
        for (int x = 0; x < alignedWidth; x++) {
            int bgraIdx = (y * alignedWidth + x) * 4;
            uint8_t b = bgraData[bgraIdx];
            uint8_t g = bgraData[bgraIdx + 1];
            uint8_t r = bgraData[bgraIdx + 2];

            // Y
            int Y = (int)(0.299 * r + 0.587 * g + 0.114 * b);
            yPtr[y * alignedWidth + x] = (uint8_t)(Y < 0 ? 0 : (Y > 255 ? 255 : Y));

            // UV (每 2x2 像素采样一次)
            if (y % 2 == 0 && x % 2 == 0) {
                int U = (int)(-0.169 * r - 0.331 * g + 0.500 * b + 128);
                int V = (int)(0.500 * r - 0.419 * g - 0.081 * b + 128);

                // NV12: UVUV...
                int uvIdx = (y / 2) * alignedWidth + x;
                uvPtr[uvIdx] = (uint8_t)(U < 0 ? 0 : (U > 255 ? 255 : U));
                uvPtr[uvIdx + 1] = (uint8_t)(V < 0 ? 0 : (V > 255 ? 255 : V));
            }
        }
    }

    free(bgraData); // 释放 BGRA 临时内存

    ASVLOFFSCREEN offscreen = {0};
    offscreen.u32PixelArrayFormat = ASVL_PAF_NV12; // NV12
    offscreen.i32Width = (int)alignedWidth;
    offscreen.i32Height = (int)alignedHeight;
    offscreen.ppu8Plane[0] = nv12Data;
    offscreen.ppu8Plane[1] = nv12Data + ySize;
    offscreen.pi32Pitch[0] = (int)alignedWidth;
    offscreen.pi32Pitch[1] = (int)alignedWidth;

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
  @synchronized (self.engine) {
      return [self detectFaces:offscreen
                   usingEngine:self.engine
             processAttributes:YES];
  }
}

/**
 * 在指定引擎上检测并复制 ArcSoft 的 faceDataInfo。
 * VIDEO 跟踪结果可异步交给识别引擎提特征；IMAGE 路径则使用高精度引擎。
 */
- (NSArray<NSDictionary *> *)detectFaces:(ASVLOFFSCREEN *)offscreen
                             usingEngine:(ArcSoftFaceEngine *)targetEngine
                       processAttributes:(BOOL)processAttributes {
      if (!self.inited || offscreen == NULL) {
          return @[];
      }

      ASF_MultiFaceInfo faces = {0};
      MRESULT result = [targetEngine detectFacesWithWidth:offscreen->i32Width
                                                   height:offscreen->i32Height
                                                     data:offscreen->ppu8Plane[0]
                                                   format:offscreen->u32PixelArrayFormat
                                                  faceRes:&faces];

      if (result != MOK) {
          return @[];
      }

      if (processAttributes) {
          [self processFaces:offscreen faces:&faces];
      }

      NSMutableArray *out = [NSMutableArray arrayWithCapacity:faces.faceNum];
      for (int i = 0; i < faces.faceNum; i++) {
        MRECT r = faces.faceRect[i];

        // 提取 faceDataInfo 并序列化
        // 这是 extractFeature 所必需的
        ASF_FaceDataInfo dataInfo = faces.faceDataInfoList[i];
        NSData *faceData = [NSData dataWithBytes:dataInfo.data length:dataInfo.dataSize];

        NSMutableDictionary *faceResult = [@{
          @"rect": @{ @"left": @(r.left), @"top": @(r.top), @"right": @(r.right), @"bottom": @(r.bottom) },
          @"orient": @(faces.faceOrient[i]),
          @"faceId": @(faces.faceID[i]), // 返回 faceId (Image模式下为-1，Video模式下有效)
          @"faceDataInfo": faceData // 传递 faceDataInfo
        } mutableCopy];
        // ArcSoft VIDEO 检测结果自身携带 3D 姿态，不额外执行属性模型。
        // 指针缺失时不伪造 0 度，交给上层明确阻止注册。
        if (faces.face3DAngleInfo.yaw &&
            faces.face3DAngleInfo.pitch &&
            faces.face3DAngleInfo.roll) {
          faceResult[@"angle"] = @{
            @"yaw": @(faces.face3DAngleInfo.yaw[i]),
            @"pitch": @(faces.face3DAngleInfo.pitch[i]),
            @"roll": @(faces.face3DAngleInfo.roll[i]),
            @"valid": @YES
          };
        }
        [out addObject:faceResult];
      }
      return out;
}

/**
 * 人脸检测 (图片)
 */
- (NSArray<NSDictionary *> *)detectFacesFromImage:(UIImage *)image {
    if (!self.inited || !image) {
        // NSLog(@"[ArcsoftEngineManager] detectFacesFromImage: invalid input. inited=%d, image=%@", self.inited, image);
        return @[];
    }

    // NSLog(@"[ArcsoftEngineManager] detectFacesFromImage: image size={%f, %f}, scale=%f", image.size.width, image.size.height, image.scale);

    ASVLOFFSCREEN offscreen = [self offscreenFromImage:image];
    // NSLog(@"[ArcsoftEngineManager] detectFacesFromImage: offscreen created. width=%d, height=%d, format=0x%x", offscreen.i32Width, offscreen.i32Height, offscreen.u32PixelArrayFormat);

    NSArray<NSDictionary *> *faces;
    // 静态图检测仍复用检测引擎；只有特征提取和检索进入识别引擎。
    @synchronized (self.engine) {
        faces = [self detectFaces:&offscreen
                      usingEngine:self.engine
                processAttributes:NO];
    }
    // NSLog(@"[ArcsoftEngineManager] detectFacesFromImage: detected %lu faces", (unsigned long)faces.count);

    [self freeOffscreen:&offscreen];
    return faces;
}

/**
 * 提取人脸特征 (视频流)
 */
- (NSString *)extractFeature:(ASVLOFFSCREEN *)offscreen
                    faceRect:(MRECT)rect
                      orient:(int)orient
                faceDataInfo:(NSData *)faceDataInfo {
  @synchronized (self.recognitionEngine) {
      if (!self.inited || offscreen == NULL) return nil;

      // 确保 rect 4字节对齐
      MRECT alignedRect = rect;
      alignedRect.left = (alignedRect.left / 4) * 4;
      alignedRect.top = (alignedRect.top / 4) * 4;
      alignedRect.right = (alignedRect.right / 4) * 4;
      alignedRect.bottom = (alignedRect.bottom / 4) * 4;

      ASF_SingleFaceInfo info = {0};
      info.faceRect = alignedRect;
      info.faceOrient = orient;

      // 填充 faceDataInfo (必须)
      if (faceDataInfo) {
          info.faceDataInfo.data = (MByte *)faceDataInfo.bytes;
          info.faceDataInfo.dataSize = (MInt32)faceDataInfo.length;
      }

      ASF_FaceFeature feature = {0};
      MRESULT result = [self.recognitionEngine extractFaceFeatureWithWidth:offscreen->i32Width
                                                                     height:offscreen->i32Height
                                                                       data:offscreen->ppu8Plane[0]
                                                                     format:offscreen->u32PixelArrayFormat
                                                                   faceInfo:&info
                                                                    feature:&feature];

      if (result != MOK) {
          NSLog(@"[ArcsoftEngineManager] extractFaceFeature failed: %ld", (long)result);
          return nil;
      }
      if (feature.featureSize <= 0 || feature.feature == NULL) {
          NSLog(@"[ArcsoftEngineManager] extractFaceFeature returned empty feature");
          return nil;
      }

      NSData *data = [NSData dataWithBytes:feature.feature length:(NSUInteger)feature.featureSize];
      return [data base64EncodedStringWithOptions:0];
  }
}

- (nullable NSDictionary *)recognizeFace:(ASVLOFFSCREEN *)offscreen
                                faceRect:(MRECT)rect
                                  orient:(int)orient
                            faceDataInfo:(nullable NSData *)faceDataInfo
                               threshold:(float)threshold
                     returnFeatureBase64:(BOOL)returnFeatureBase64 {
  @synchronized (self.recognitionEngine) {
      if (!self.inited || offscreen == NULL) return nil;

      MRECT alignedRect = rect;
      alignedRect.left = (alignedRect.left / 4) * 4;
      alignedRect.top = (alignedRect.top / 4) * 4;
      alignedRect.right = (alignedRect.right / 4) * 4;
      alignedRect.bottom = (alignedRect.bottom / 4) * 4;

      ASF_SingleFaceInfo info = {0};
      info.faceRect = alignedRect;
      info.faceOrient = orient;
      if (faceDataInfo.length > 0) {
          info.faceDataInfo.data = (MByte *)faceDataInfo.bytes;
          info.faceDataInfo.dataSize = (MInt32)faceDataInfo.length;
      }

      ASF_FaceFeature feature = {0};
      MRESULT extractResult = [self.recognitionEngine extractFaceFeatureWithWidth:offscreen->i32Width
                                                                            height:offscreen->i32Height
                                                                              data:offscreen->ppu8Plane[0]
                                                                            format:offscreen->u32PixelArrayFormat
                                                                          faceInfo:&info
                                                                           feature:&feature];
      if (extractResult != MOK || feature.feature == NULL || feature.featureSize <= 0) {
          return nil;
      }

      ASF_FaceFeatureInfo resultInfo = {0};
      MFloat confidence = 0.0f;
      MRESULT searchResult = [self.recognitionEngine searchFaceFeatureWithFeature:&feature
                                                                      compareModel:ASF_LIFE_PHOTO
                                                                        similarity:&confidence
                                                                   faceFeatureInfo:&resultInfo];
      if (searchResult != MOK || confidence < threshold) {
          return nil;
      }

      NSString *userId = self.searchIdToUser[@(resultInfo.searchId)];
      if (userId.length == 0) return nil;

      NSMutableDictionary *result = [@{
          @"id": userId,
          @"score": @(confidence)
      } mutableCopy];
      if (returnFeatureBase64) {
          NSData *featureData = [NSData dataWithBytes:feature.feature
                                               length:(NSUInteger)feature.featureSize];
          result[@"featureBase64"] = [featureData base64EncodedStringWithOptions:0];
      }
      return result;
  }
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

    // 从 faceInfo 中获取 faceDataInfo
    NSData *faceDataInfo = faceInfo[@"faceDataInfo"];

    NSString *feature = [self extractFeature:&offscreen faceRect:rect orient:orient faceDataInfo:faceDataInfo];

    [self freeOffscreen:&offscreen];
    return feature;
}

/**
 * 特征比对
 */
- (float)compareFeature1:(NSData *)f1 feature2:(NSData *)f2 {
  @synchronized (self.recognitionEngine) {
      if (!self.inited || !f1 || !f2) return 0.f;

      ASF_FaceFeature ff1 = {0};
      ff1.featureSize = (int)f1.length;
      ff1.feature = (MByte *)f1.bytes;

      ASF_FaceFeature ff2 = {0};
      ff2.featureSize = (int)f2.length;
      ff2.feature = (MByte *)f2.bytes;

      MFloat confidenceLevel = 0.0;
      [self.recognitionEngine compareFaceWithFeature:&ff1 feature2:&ff2 confidenceLevel:&confidenceLevel];
      return confidenceLevel;
  }
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
    @synchronized (self.recognitionEngine) {
        if (!self.inited || !userId.length || !featureData.length) return NO;

        // 1. Check if exists in DB
        // Note: FaceDB is not directly accessible here, but we can check userToSearchId
        NSNumber *existingId = self.userToSearchId[userId];
        if (existingId) {
            // Remove old face first
            [[FaceDB sharedInstance] removeFace:userId];
            [self.recognitionEngine removeFaceFeatureWithSearchId:[existingId intValue]];
            [self.userToSearchId removeObjectForKey:userId];
            [self.searchIdToUser removeObjectForKey:existingId];
        }

        // 2. Save to DB
        [[FaceDB sharedInstance] addFace:userId feature:featureData];

        // 3. Add to Engine
        int searchId = self.nextSearchId++;

        // 构造注册信息
        ASF_FaceFeature featureStruct = {0};
        featureStruct.feature = (MByte *)featureData.bytes;
        featureStruct.featureSize = (MInt32)featureData.length;

        ASF_FaceFeatureInfo info = {0};
        info.searchId = searchId;
        info.feature = &featureStruct;
        info.tag = "";

        // 调用引擎注册
        MRESULT mr = [self.recognitionEngine registerSingleFaceFeatureWithFeatureInfo:&info];
        if (mr == MOK) {
            // 更新映射
            self.userToSearchId[userId] = @(searchId);
            self.searchIdToUser[@(searchId)] = userId;
            // Clear cache
            [self clearCache];
            return YES;
        }

        return NO;
    }
}

/**
 * 移除人脸特征
 */
- (BOOL)faceDBRemove:(NSString *)userId {
    @synchronized (self.recognitionEngine) {
        if (!self.inited || !userId.length) return NO;

        // 1. Remove from DB
        [[FaceDB sharedInstance] removeFace:userId];

        // 2. Remove from Engine
        NSNumber *searchId = self.userToSearchId[userId];
        if (!searchId) return NO;

        MRESULT mr = [self.recognitionEngine removeFaceFeatureWithSearchId:[searchId intValue]];

        // 无论引擎返回成功与否，都清理本地映射
        [self.userToSearchId removeObjectForKey:userId];
        [self.searchIdToUser removeObjectForKey:searchId];

        // 3. Clear cache
        [self clearCache];

        return (mr == MOK);
    }
}

/**
 * 清空人脸库
 */
- (BOOL)faceDBClear {
    @synchronized (self.recognitionEngine) {
        if (!self.inited) return NO;

        // 1. Clear DB
        [[FaceDB sharedInstance] clearAll];

        // 2. Clear Engine
        MRESULT mr = [self.recognitionEngine clearAllFaceFeature];

        [self.userToSearchId removeAllObjects];
        [self.searchIdToUser removeAllObjects];
        self.nextSearchId = 1000;

        // 3. Clear cache
        [self clearCache];

        return (mr == MOK);
    }
}

/**
 * 获取人脸库数量
 */
- (NSInteger)faceDBCount {
//     if (!self.inited) return 0;

    // Return count from DB
    return [[FaceDB sharedInstance] count];
}

/**
 * 获取所有人脸列表
 * @param userId 可选的用户ID，如果提供则只返回该用户的数据
 * @return 包含 { "id": userId } 的列表
 */
- (NSArray<NSDictionary *> *)faceDBGetAllFaces:(NSString *)userId {
    // 从 FaceDB 获取记录
    NSArray<FaceRecord *> *records;
    if (userId && userId.length > 0) {
        records = [[FaceDB sharedInstance] getFacesByUserId:userId];
    } else {
        records = [[FaceDB sharedInstance] getAllFaces];
    }

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:records.count];

    for (FaceRecord *record in records) {
        if (record.userId) {
            [result addObject:@{
                @"id": [NSString stringWithFormat:@"%ld", (long)record.id],
                @"userId": record.userId,
                @"registerTime": @(record.registerTime)
            }];
        }
    }
    return result;
}

/**
 * 搜索人脸 (1:N)
 */
- (NSDictionary * _Nullable)faceDBSearchTop1:(NSData *)featureData threshold:(float)threshold {
    @synchronized (self.recognitionEngine) {
        if (!self.inited || !featureData.length) return nil;

        ASF_FaceFeature feature = {0};
        feature.feature = (MByte *)featureData.bytes;
        feature.featureSize = (MInt32)featureData.length;

        ASF_FaceFeatureInfo resultInfo = {0};
        MFloat confidence = 0.0f;

        // 1:N 搜索
        MRESULT mr = [self.recognitionEngine searchFaceFeatureWithFeature:&feature
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
}

@end
