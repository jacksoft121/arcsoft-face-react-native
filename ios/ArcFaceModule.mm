#import <React/RCTBridgeModule.h>
#import "FaceRegistry.h"

@interface ArcFaceModule : NSObject <RCTBridgeModule>
@end

@implementation ArcFaceModule

RCT_EXPORT_MODULE(ArcFaceModule)

RCT_EXPORT_METHOD(registryLoadAll:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  [FaceRegistry load];
  resolve(nil);
}

RCT_EXPORT_METHOD(registryUpsert:(NSString *)userId
                  featureBase64:(NSString *)b64
                  featureSize:(nonnull NSNumber *)size
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSData *data = [[NSData alloc] initWithBase64EncodedString:b64 options:0];
  if (data) {
    [FaceRegistry upsert:userId feature:data];
  }
  resolve(nil);
}

@end
