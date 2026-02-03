#import "ArcSoftFaceModule.h"
#import "ArcSoftFaceManager.h"

@implementation ArcSoftFaceModule

RCT_EXPORT_MODULE(ArcSoftFace);

RCT_EXPORT_METHOD(activate:(NSString *)appId
                  sdkKey:(NSString *)sdkKey
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    int code = [[ArcSoftFaceManager shared] activateWithAppId:appId sdkKey:sdkKey];
    resolve(@(code));
}

RCT_EXPORT_METHOD(init:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    int code = [[ArcSoftFaceManager shared] initEngine];
    resolve(@(code));
}

RCT_EXPORT_METHOD(detectFaces:(NSString *)nv21Base64
                  width:(int)width
                  height:(int)height
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {

    NSData *data = [[NSData alloc] initWithBase64EncodedString:nv21Base64 options:0];
    NSArray *res = [[ArcSoftFaceManager shared] detectFacesFromNV21:data width:width height:height];
    resolve(res);
}

RCT_EXPORT_METHOD(extractFeature:(NSString *)nv21Base64
                  width:(int)width
                  height:(int)height
                  faceIndex:(int)faceIndex
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {

    NSData *data = [[NSData alloc] initWithBase64EncodedString:nv21Base64 options:0];
    NSDictionary *res = [[ArcSoftFaceManager shared]
        extractFeatureFromNV21:data width:width height:height faceIndex:faceIndex];
    resolve(res);
}

@end
