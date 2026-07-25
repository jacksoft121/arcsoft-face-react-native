#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

@interface ArcsoftFrameDetectorRuntime : NSObject

+ (NSDictionary *)detectFacesInPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                   options:(NSDictionary *)options
    NS_SWIFT_NAME(detectFaces(pixelBuffer:options:));

@end

NS_ASSUME_NONNULL_END
