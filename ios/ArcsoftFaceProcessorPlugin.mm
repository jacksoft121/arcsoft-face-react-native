#import <VisionCamera/FrameProcessorPlugin.h>
#import <VisionCamera/FrameProcessorPluginRegistry.h>
#import <VisionCamera/Frame.h>
#import "ArcsoftEngineManager.h"
#import "PixelBufferUtils.h"

@interface ArcsoftFaceProcessorPlugin : FrameProcessorPlugin
@end

@implementation ArcsoftFaceProcessorPlugin

static int DEFAULT_MAX_RETRY_COUNT = 5;

- (instancetype)initWithProxy:(VisionCameraProxyHolder*)proxy
                  withOptions:(NSDictionary* _Nullable)options {
  if (self = [super initWithProxy:proxy withOptions:options]) {
    // init
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
      [[ArcsoftEngineManager sharedInstance] cleanUpFaceStates:faces];

      enrichedFaces = [NSMutableArray arrayWithCapacity:faces.count];
      for (NSDictionary *face in faces) {
          NSMutableDictionary *faceMutable = [face mutableCopy];

          // 3.2 特征提取 (如果开启)
          if (extractFeature) {
              // 尝试获取 faceID
              NSNumber *faceIdNum = faceMutable[@"faceId"]; // 注意：detectFaces 需要返回 faceId
              int faceId = [faceIdNum intValue];

              // 优化策略：检查是否需要处理
              if (![[ArcsoftEngineManager sharedInstance] shouldProcessFace:faceId maxRetryCount:maxRetryCount]) {
                  // 不需要处理（已识别或重试超限），尝试获取缓存信息
                  NSDictionary *cachedInfo = [[ArcsoftEngineManager sharedInstance] getCachedFaceInfo:faceId];
                  if (cachedInfo) {
                      [faceMutable addEntriesFromDictionary:cachedInfo];
                  }
              } else {
                  // 需要处理
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

                          // 识别成功，更新缓存
                          [[ArcsoftEngineManager sharedInstance] updateFaceCache:faceId userId:userId score:[score floatValue] featureBase64:featBase64];
                      } else {
                          // 识别失败，增加重试计数，但缓存特征值
                          [[ArcsoftEngineManager sharedInstance] updateRetryCount:faceId];
                          [[ArcsoftEngineManager sharedInstance] updateFaceCache:faceId userId:nil score:0 featureBase64:featBase64];
                      }
                  } else {
                      // 特征提取失败
                      // NSLog(@"[ArcsoftFace] Feature extraction failed");
                      [[ArcsoftEngineManager sharedInstance] updateRetryCount:faceId];
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
