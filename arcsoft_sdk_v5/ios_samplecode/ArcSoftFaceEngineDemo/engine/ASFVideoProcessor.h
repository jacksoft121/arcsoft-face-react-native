//
//  ASFVideoProcessor.h
//

#import <Foundation/Foundation.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngineDefine.h>
#import "Utility.h"

@class ASFRPerson;
@protocol ASFVideoProcessorDelegate <NSObject>

- (void)processRecognized:(NSString*)personName;

@end


@protocol ASFVideoFlashLivenessDelegate <NSObject>

- (void)showLiveneeTips:(NSString*)tips;
-(void) updateLivenessResult:(NSInteger)ret
                 livenessRes:(NSInteger)livenessRes;
@end

@interface ASFFace3DAngle : NSObject
@property(nonatomic,assign) MFloat rollAngle;
@property(nonatomic,assign) MFloat yawAngle;
@property(nonatomic,assign) MFloat pitchAngle;
@property(nonatomic,assign) MInt32 status;
@end

@interface ASFVideoFaceInfo : NSObject
@property(nonatomic,assign) MRECT faceRect;
@property(nonatomic,assign) MInt32 age;
@property(nonatomic,assign) MInt32 gender;
@property(nonatomic,strong) ASFFace3DAngle *face3DAngle;
@property(nonatomic, assign) MInt32 liveness;
@end




@interface ASFVideoProcessor : NSObject

@property(nonatomic, assign) BOOL detectFaceUseFD;
@property(nonatomic, weak) id<ASFVideoProcessorDelegate> delegate;
@property(nonatomic, weak) id<ASFVideoFlashLivenessDelegate> flashDelegate;
- (void)initProcessor;
- (void)uninitProcessor;
- (NSArray*)process:(ASF_CAMERA_DATA*)offscreen;
- (BOOL)registerDetectedPerson:(NSString*)personName;
-(NSInteger)screenFlashDetect:(ASF_CAMERA_DATA*)cameraData
                    flashOrder:(ASF_ColorCode)order
                   flashColor:(ASF_FlashColor)color
                    isReset:(int)reset
                  isLastFrame:(bool)lastFrame;

-(NSInteger)actionDetect:(ASF_CAMERA_DATA*)cameraData
                  action:(int)action
                 isReset:(int)reset;



@end
