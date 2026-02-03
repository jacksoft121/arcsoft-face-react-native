#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import "NativeArcFaceSpec.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface ArcSoftFace : NSObject
#ifdef RCT_NEW_ARCH_ENABLED
<NativeArcFaceSpec>
#else
<RCTBridgeModule>
#endif
@end

NS_ASSUME_NONNULL_END
