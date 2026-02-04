#import <Foundation/Foundation.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import "ArcSoftFaceReactNativeSpec.h"
@interface ArcsoftFaceModule : NSObject <NativeArcsoftFaceSpec>
@end
#else
#import <React/RCTBridgeModule.h>
@interface ArcsoftFaceModule : NSObject <RCTBridgeModule>
@end
#endif
