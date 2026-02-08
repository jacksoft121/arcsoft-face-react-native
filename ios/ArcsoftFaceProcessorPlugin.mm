#import <VisionCamera/FrameProcessorPlugin.h>
#import <VisionCamera/FrameProcessorPluginRegistry.h>
#import <VisionCamera/Frame.h>
#import "ArcsoftEngineManager.h"
#import "PixelBufferUtils.h"

@interface ArcsoftFaceProcessorPlugin : FrameProcessorPlugin
@end

@implementation ArcsoftFaceProcessorPlugin

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

  if (arguments) {
      if (arguments[@"saveImage"]) saveImage = [arguments[@"saveImage"] boolValue];
      if (arguments[@"extractFeature"]) extractFeature = [arguments[@"extractFeature"] boolValue];
      if (arguments[@"score"]) scoreThreshold = [arguments[@"score"] doubleValue];
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

      enrichedFaces = [NSMutableArray arrayWithCapacity:faces.count];
      for (NSDictionary *face in faces) {
          NSMutableDictionary *faceMutable = [face mutableCopy];

          // 3.2 特征提取 (如果开启)
          if (extractFeature) {
              NSDictionary *rectDict = face[@"rect"];
              MRECT rect = {
                  [rectDict[@"left"] intValue], [rectDict[@"top"] intValue],
                  [rectDict[@"right"] intValue], [rectDict[@"bottom"] intValue]
              };
              int orient = [face[@"orient"] intValue];

              // 获取 faceDataInfo (从 detectFaces 结果中获取)
              NSData *faceDataInfo = face[@"faceDataInfo"];

              // 提取特征 (Base64)
              // 注意：这里传入的 offscreen 必须是 copy 过的，因为 ArcSoft SDK 在 extractFeature 时
              // 可能会修改或依赖 offscreen 的内存布局。
              // 官方 Demo 中，detectFaces 和 extractFeature 使用的是同一份 cameraData。
              // 但在多线程环境下，官方 Demo 复制了一份 cameraData 给 FR 线程 (copyCameraDataForProcessFR)。
              // 我们这里是在同一个 Block (同一个线程) 中顺序执行，理论上可以直接使用 offscreen。
              // 但是，PixelBufferUtils 提供的 offscreen 是临时的，且去除了 padding。
              // 只要 detectFaces 和 extractFeature 都接受这种紧凑格式即可。

              NSString *featBase64 = [[ArcsoftEngineManager sharedInstance] extractFeature:offscreen faceRect:rect orient:orient faceDataInfo:faceDataInfo];

              if (featBase64) {
                  faceMutable[@"featureBase64"] = featBase64;

                  // 3.3 自动搜索人脸库 (1:N)
                  NSData *featureData = [[NSData alloc] initWithBase64EncodedString:featBase64 options:0];
                  NSDictionary *searchResult = [[ArcsoftEngineManager sharedInstance] faceDBSearchTop1:featureData threshold:scoreThreshold];

                  if (searchResult) {
                      faceMutable[@"userId"] = searchResult[@"id"];
                      faceMutable[@"score"] = searchResult[@"score"];
                  }
              } else {
                  // 特征提取失败 (可能是人脸质量不高或角度问题)
                  // NSLog(@"[ArcsoftFace] Feature extraction failed");
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
