#import "ArcsoftFrameDetectorRuntime.h"
#import "ArcsoftEngineManager.h"
#import "PixelBufferUtils.h"

#import <CoreImage/CoreImage.h>
#import <UIKit/UIKit.h>

@implementation ArcsoftFrameDetectorRuntime

static int const DEFAULT_MAX_RETRY_COUNT = 3;

/** ArcSoft 同一识别引擎只串行调用，并且只允许等待一个最新批次。 */
static dispatch_queue_t ArcsoftRecognitionQueue(void) {
  static dispatch_queue_t queue;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    queue = dispatch_queue_create("com.dlxsoft.arcsoft.recognition", DISPATCH_QUEUE_SERIAL);
  });
  return queue;
}

static dispatch_semaphore_t ArcsoftRecognitionSlot(void) {
  static dispatch_semaphore_t semaphore;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    semaphore = dispatch_semaphore_create(1);
  });
  return semaphore;
}

+ (NSDictionary *)detectFacesInPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                   options:(NSDictionary *)options {
  if (!pixelBuffer) {
    return @{ @"faces": @[] };
  }

  NSDictionary *arguments = options ?: @{};
  BOOL saveImage = [arguments[@"saveImage"] boolValue];
  NSString *captureUserIds = [arguments[@"captureUserIds"] isKindOfClass:NSString.class]
    ? arguments[@"captureUserIds"]
    : @"";
  BOOL extractFeature = [arguments[@"extractFeature"] boolValue];
  BOOL retExtractFeatureBase64 = [arguments[@"retExtractFeatureBase64"] boolValue];
  double scoreThreshold = arguments[@"score"] ? [arguments[@"score"] doubleValue] : 0.8;
  int maxRetryCount = arguments[@"maxRetryCount"]
    ? [arguments[@"maxRetryCount"] intValue]
    : DEFAULT_MAX_RETRY_COUNT;

  __block NSMutableArray *enrichedFaces = nil;
  __block BOOL shouldSaveFrame = saveImage && captureUserIds.length == 0;

  [PixelBufferUtils useOffscreenFromPixelBuffer:pixelBuffer block:^(ASVLOFFSCREEN *offscreen) {
    NSArray<NSDictionary *> *faces = [[ArcsoftEngineManager sharedInstance] detectFaces:offscreen];
    [[ArcsoftEngineManager sharedInstance] cleanUpFaceStates:faces];

    enrichedFaces = [NSMutableArray arrayWithCapacity:faces.count];
    for (NSDictionary *face in faces) {
      NSMutableDictionary *faceMutable = [face mutableCopy];

      // 所有检测帧都返回同一 faceID 已确认的姓名；特征帧只负责异步更新缓存。
      NSDictionary *cachedInfo = [[ArcsoftEngineManager sharedInstance]
        getCachedFaceInfo:[face[@"faceId"] intValue]];
      if (cachedInfo) {
        [faceMutable addEntriesFromDictionary:cachedInfo];
      }
      if (!retExtractFeatureBase64) {
        [faceMutable removeObjectForKey:@"featureBase64"];
      }

      NSString *userId = faceMutable[@"userId"];
      if (saveImage &&
          captureUserIds.length > 0 &&
          userId.length > 0 &&
          [captureUserIds containsString:[NSString stringWithFormat:@",%@,", userId]]) {
        shouldSaveFrame = YES;
      }

      [faceMutable removeObjectForKey:@"faceDataInfo"];
      [enrichedFaces addObject:faceMutable];
    }

    if (extractFeature && faces.count > 0) {
      [self scheduleRecognitionForFaces:faces
                              offscreen:offscreen
             returnFeatureBase64:retExtractFeatureBase64
                      threshold:(float)scoreThreshold
                   maxRetryCount:maxRetryCount];
    }
  }];

  NSString *imagePath = shouldSaveFrame ? [self saveFrame:pixelBuffer] : nil;
  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  result[@"faces"] = enrichedFaces ?: @[];
  if (imagePath) {
    result[@"imagePath"] = imagePath;
  }
  return result;
}

+ (void)scheduleRecognitionForFaces:(NSArray<NSDictionary *> *)faces
                           offscreen:(ASVLOFFSCREEN *)offscreen
          returnFeatureBase64:(BOOL)returnFeatureBase64
                   threshold:(float)threshold
                maxRetryCount:(int)maxRetryCount {
  if (
      !offscreen ||
      dispatch_semaphore_wait(ArcsoftRecognitionSlot(), DISPATCH_TIME_NOW) != 0
  ) {
    return;
  }

  ArcsoftEngineManager *manager = [ArcsoftEngineManager sharedInstance];
  NSMutableArray<NSDictionary *> *pending = [NSMutableArray array];
  for (NSDictionary *face in faces) {
    NSNumber *faceId = face[@"faceId"];
    NSDictionary *rect = face[@"rect"];
    if (!faceId || !rect) continue;

    NSInteger generation = [manager tryBeginFaceRecognition:faceId.intValue
                                              maxRetryCount:maxRetryCount];
    if (generation >= 0) {
      [pending addObject:@{
        @"face": face,
        @"generation": @(generation)
      }];
    }
  }

  if (pending.count == 0) {
    dispatch_semaphore_signal(ArcsoftRecognitionSlot());
    return;
  }

  int plane0Size = offscreen->pi32Pitch[0] * offscreen->i32Height;
  int plane1Size = 0;
  if (offscreen->u32PixelArrayFormat == ASVL_PAF_NV12) {
    plane1Size = offscreen->pi32Pitch[1] * offscreen->i32Height / 2;
  } else if (offscreen->u32PixelArrayFormat != ASVL_PAF_RGB32_B8G8R8A8) {
    for (NSDictionary *item in pending) {
      NSDictionary *face = item[@"face"];
      [manager cancelFaceRecognition:[face[@"faceId"] intValue]
                          generation:[item[@"generation"] integerValue]];
    }
    dispatch_semaphore_signal(ArcsoftRecognitionSlot());
    return;
  }

  // PixelBufferUtils 已把平面紧凑排在连续内存中；仅在实际需要识别时复制一次。
  NSData *frameData = [NSData dataWithBytes:offscreen->ppu8Plane[0]
                                     length:(NSUInteger)(plane0Size + plane1Size)];
  int width = offscreen->i32Width;
  int height = offscreen->i32Height;
  int format = offscreen->u32PixelArrayFormat;
  int pitch0 = offscreen->pi32Pitch[0];
  int pitch1 = offscreen->pi32Pitch[1];

  dispatch_async(ArcsoftRecognitionQueue(), ^{
    @autoreleasepool {
      @try {
        ASVLOFFSCREEN snapshot = {0};
        snapshot.i32Width = width;
        snapshot.i32Height = height;
        snapshot.u32PixelArrayFormat = format;
        snapshot.pi32Pitch[0] = pitch0;
        snapshot.pi32Pitch[1] = pitch1;
        snapshot.ppu8Plane[0] = (MUInt8 *)frameData.bytes;
        if (plane1Size > 0) {
          snapshot.ppu8Plane[1] = snapshot.ppu8Plane[0] + plane0Size;
        }

        for (NSDictionary *item in pending) {
          NSDictionary *face = item[@"face"];
          NSDictionary *rectDict = face[@"rect"];
          int faceId = [face[@"faceId"] intValue];
          NSInteger generation = [item[@"generation"] integerValue];
          MRECT rect = {
            [rectDict[@"left"] intValue],
            [rectDict[@"top"] intValue],
            [rectDict[@"right"] intValue],
            [rectDict[@"bottom"] intValue]
          };
          NSDictionary *result = [manager recognizeFace:&snapshot
                                               faceRect:rect
                                                 orient:[face[@"orient"] intValue]
                                           faceDataInfo:face[@"faceDataInfo"]
                                              threshold:threshold
                                    returnFeatureBase64:returnFeatureBase64];
          [manager completeFaceRecognition:faceId
                                generation:generation
                                     result:result];
        }
      } @finally {
        dispatch_semaphore_signal(ArcsoftRecognitionSlot());
      }
    }
  });
}

+ (NSString *)saveFrame:(CVPixelBufferRef)pixelBuffer {
  CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
  CIContext *context = [CIContext context];
  CGImageRef cgImage = [context createCGImage:ciImage fromRect:ciImage.extent];
  if (!cgImage) {
    return nil;
  }

  UIImage *uiImage = [UIImage imageWithCGImage:cgImage];
  CGImageRelease(cgImage);

  NSData *data = UIImageJPEGRepresentation(uiImage, 0.92);
  if (!data) {
    return nil;
  }

  NSString *fileName = [NSString stringWithFormat:@"face_%lld.jpg", (long long)(NSDate.date.timeIntervalSince1970 * 1000)];
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = paths.firstObject;
  NSString *path = [documentsDirectory stringByAppendingPathComponent:fileName];

  if ([data writeToFile:path atomically:YES]) {
    NSLog(@"[ArcsoftFace] Saved frame to %@", path);
    return [@"file://" stringByAppendingString:path];
  }
  return nil;
}

@end
