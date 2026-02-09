#import <VisionCamera/FrameProcessorPlugin.h>
#import <VisionCamera/FrameProcessorPluginRegistry.h>
#import <VisionCamera/Frame.h>
#import "ArcsoftEngineManager.h"
#import "PixelBufferUtils.h"

@interface ArcsoftFaceProcessorPlugin : FrameProcessorPlugin
// 优化策略：记录已处理的 faceId 和重试次数
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *processedFaceIds; // faceId -> userId
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *faceRetryCounts; // faceId -> retry count
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *faceScores; // faceId -> score
@end

@implementation ArcsoftFaceProcessorPlugin

static int DEFAULT_MAX_RETRY_COUNT = 5;

- (instancetype)initWithProxy:(VisionCameraProxyHolder*)proxy
                  withOptions:(NSDictionary* _Nullable)options {
  if (self = [super initWithProxy:proxy withOptions:options]) {
    _processedFaceIds = [NSMutableDictionary dictionary];
    _faceRetryCounts = [NSMutableDictionary dictionary];
    _faceScores = [NSMutableDictionary dictionary];
  }
  return self;
}

/**
 * VisionCamera 帧处理回调
 *
 * @param frame 视频帧对象，包含 buffer
 * @param arguments JS 传递的参数，例如 { "extractFeature": true, "score": 0.8 }
 * @return 返回给 JS 的结果字典
 */
- (id)callback:(Frame*)frame withArguments:(NSDictionary* _Nullable)arguments {
  // [Log] 入参日志 (调试时可开启)
  // NSLog(@"[ArcsoftFace] callback called. arguments: %@", arguments);

  CMSampleBufferRef buffer = frame.buffer;
  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(buffer);

  if (!pixelBuffer) {
      // NSLog(@"[ArcsoftFace] Error: pixelBuffer is nil");
      return nil;
  }

  // 1. 解析参数
  BOOL saveImage = NO;
  BOOL extractFeature = NO;
  double scoreThreshold = 0.8; // 默认相似度阈值
  int maxRetryCount = DEFAULT_MAX_RETRY_COUNT;

  if (arguments) {
      if (arguments[@"saveImage"]) saveImage = [arguments[@"saveImage"] boolValue];
      if (arguments[@"extractFeature"]) extractFeature = [arguments[@"extractFeature"] boolValue];
      if (arguments[@"score"]) scoreThreshold = [arguments[@"score"] doubleValue];
      if (arguments[@"maxRetryCount"]) maxRetryCount = [arguments[@"maxRetryCount"] intValue];
  }

  // 2. 保存图片 (调试用)
  NSString *imagePath = nil;
  if (saveImage) {
      imagePath = [self saveFrame:pixelBuffer];
  }

  __block NSMutableArray *enrichedFaces = nil;

  // 3. 使用 PixelBufferUtils 处理图像数据
  // 该方法会自动处理 CVPixelBuffer 的 Lock/Unlock 以及 stride padding 的去除，
  // 确保传递给 ArcSoft SDK 的是紧凑的内存块。
  [PixelBufferUtils useOffscreenFromPixelBuffer:pixelBuffer block:^(ASVLOFFSCREEN *offscreen) {

      // 3.1 人脸检测
      NSArray<NSDictionary *> *faces = [[ArcsoftEngineManager sharedInstance] detectFaces:offscreen];

      // 清理离开画面的人脸状态
      [self cleanUpFaceStates:faces];

      enrichedFaces = [NSMutableArray arrayWithCapacity:faces.count];
      for (NSDictionary *face in faces) {
          NSMutableDictionary *faceMutable = [face mutableCopy];

          // 3.2 特征提取 (如果开启)
          if (extractFeature) {
              // 尝试获取 faceID
              NSNumber *faceIdNum = faceMutable[@"faceId"]; // 注意：detectFaces 需要返回 faceId

              BOOL needRecognition = YES;

              if (faceIdNum) {
                  // 检查是否已识别
                  NSString *cachedUserId = self.processedFaceIds[faceIdNum];
                  if (cachedUserId) {
                      // 已识别，直接使用缓存
                      faceMutable[@"userId"] = cachedUserId;
                      // 使用缓存的分数，如果没有则默认为 1.0 (虽然通常会有)
                      NSNumber *cachedScore = self.faceScores[faceIdNum];
                      faceMutable[@"score"] = cachedScore ?: @(1.0);
                      needRecognition = NO;
                  } else {
                      // 检查重试次数
                      NSNumber *retryCountNum = self.faceRetryCounts[faceIdNum];
                      int retryCount = retryCountNum ? [retryCountNum intValue] : 0;
                      if (retryCount >= maxRetryCount) {
                          // 超过重试次数，不再尝试
                          needRecognition = NO;
                      }
                  }
              }

              if (needRecognition) {
                  NSDictionary *rectDict = face[@"rect"];
                  MRECT rect = {
                      [rectDict[@"left"] intValue], [rectDict[@"top"] intValue],
                      [rectDict[@"right"] intValue], [rectDict[@"bottom"] intValue]
                  };
                  int orient = [face[@"orient"] intValue];

                  // 获取 faceDataInfo (从 detectFaces 结果中获取)
                  NSData *faceDataInfo = face[@"faceDataInfo"];

                  // 提取特征 (Base64)
                  NSString *featBase64 = [[ArcsoftEngineManager sharedInstance] extractFeature:offscreen faceRect:rect orient:orient faceDataInfo:faceDataInfo];

                  if (featBase64) {
                      faceMutable[@"featureBase64"] = featBase64;

                      // 3.3 自动搜索人脸库 (1:N)
                      NSData *featureData = [[NSData alloc] initWithBase64EncodedString:featBase64 options:0];
                      NSDictionary *searchResult = [[ArcsoftEngineManager sharedInstance] faceDBSearchTop1:featureData threshold:scoreThreshold];

                      if (searchResult) {
                          NSString *userId = searchResult[@"id"];
                          NSNumber *score = searchResult[@"score"];
                          faceMutable[@"userId"] = userId;
                          faceMutable[@"score"] = score;

                          // 识别成功，缓存状态
                          if (faceIdNum) {
                              self.processedFaceIds[faceIdNum] = userId;
                              self.faceScores[faceIdNum] = score; // 缓存分数
                              [self.faceRetryCounts removeObjectForKey:faceIdNum];
                          }
                      } else {
                          // 识别失败，增加重试计数
                          if (faceIdNum) {
                              int count = [self.faceRetryCounts[faceIdNum] intValue];
                              self.faceRetryCounts[faceIdNum] = @(count + 1);
                          }
                      }
                  } else {
                      // 特征提取失败
                      if (faceIdNum) {
                          int count = [self.faceRetryCounts[faceIdNum] intValue];
                          self.faceRetryCounts[faceIdNum] = @(count + 1);
                      }
                  }
              }
          }

          // 移除 faceDataInfo，不返回给 JS，因为数据量大且 JS 用不到
          [faceMutable removeObjectForKey:@"faceDataInfo"];

          [enrichedFaces addObject:faceMutable];
      }
  }];

  if (!enrichedFaces) {
      // NSLog(@"[ArcsoftFace] Warning: enrichedFaces is nil. Block might not have been executed (unsupported format?).");
  }

  // 4. 构造返回结果
  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  result[@"faces"] = enrichedFaces ?: @[];
  if (imagePath) {
      result[@"imagePath"] = imagePath;
  }

  return result;
}

// 清理不再画面中的人脸状态
- (void)cleanUpFaceStates:(NSArray<NSDictionary *> *)currentFaces {
    NSMutableSet<NSNumber *> *currentIds = [NSMutableSet set];
    for (NSDictionary *face in currentFaces) {
        NSNumber *fid = face[@"faceId"];
        if (fid) {
            [currentIds addObject:fid];
        }
    }

    // 移除 processedFaceIds 中不存在于 currentIds 的键
    NSMutableArray *toRemoveProcessed = [NSMutableArray array];
    for (NSNumber *fid in self.processedFaceIds) {
        if (![currentIds containsObject:fid]) {
            [toRemoveProcessed addObject:fid];
        }
    }
    [self.processedFaceIds removeObjectsForKeys:toRemoveProcessed];

    // 移除 faceScores 中不存在于 currentIds 的键
    [self.faceScores removeObjectsForKeys:toRemoveProcessed];

    // 移除 faceRetryCounts 中不存在于 currentIds 的键
    NSMutableArray *toRemoveRetry = [NSMutableArray array];
    for (NSNumber *fid in self.faceRetryCounts) {
        if (![currentIds containsObject:fid]) {
            [toRemoveRetry addObject:fid];
        }
    }
    [self.faceRetryCounts removeObjectsForKeys:toRemoveRetry];
}

/**
 * 将当前帧保存为本地 JPG 文件 (用于调试)
 */
- (NSString *)saveFrame:(CVPixelBufferRef)pixelBuffer {
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CIContext *context = [CIContext context];
    CGImageRef cgImage = [context createCGImage:ciImage fromRect:[ciImage extent]];
    UIImage *uiImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);

    NSData *data = UIImageJPEGRepresentation(uiImage, 0.8);
    NSString *fileName = [NSString stringWithFormat:@"face_%f.jpg", [[NSDate date] timeIntervalSince1970]];

    // 保存到 Documents 目录
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:fileName];

    if ([data writeToFile:path atomically:YES]) {
        NSLog(@"[ArcsoftFace] Saved frame to %@", path);
        return [@"file://" stringByAppendingString:path];
    }
    return nil;
}

VISION_EXPORT_FRAME_PROCESSOR(ArcsoftFaceProcessorPlugin, detectFaces)

@end
