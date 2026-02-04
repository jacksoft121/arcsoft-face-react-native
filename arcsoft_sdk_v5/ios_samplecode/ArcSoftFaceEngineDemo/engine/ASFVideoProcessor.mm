//
//  AFVideoProcessor.mm
//

#import "ASFVideoProcessor.h"
#import "Utility.h"
#import "ASFRManager.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngineDefine.h>
#import <ArcSoftFaceEngine/merror.h>

#define ASF_APPID            @"EXnv3N55pz6Sz1HJz2jqYmArdAkgw2hdGFnHy7R5yLcU"
#define ASF_SDKKEY           @"7hoeQjnM1qLtvcL1a8YBhv1WpHZpxyXpuHY1b8fLfEDf"
#define DETECT_MODE          ASF_DETECT_MODE_VIDEO
#define ASF_FACE_NUM         6
#define ASF_FACE_SCALE       16
#define ASF_FACE_COMBINEDMASK ASF_FACE_DETECT | ASF_FACERECOGNITION | ASF_AGE | ASF_GENDER | ASF_LIVENESS | ASF_LIVENESS_SCREENFLASH


typedef struct {
    int color;
    int reset;
    int order;
    bool lastFrame;
} ScreenFlashInfo;

@implementation ASFFace3DAngle
@end

@implementation ASFVideoFaceInfo
- (instancetype)init {
    if (self = [super init]) {
        self.liveness = -1;
    }
    return self;
}
@end

@interface ASFVideoProcessor()
{
    ASF_CAMERA_DATA*   _cameraDataForProcessFR;
    dispatch_semaphore_t _processSemaphore;
    dispatch_semaphore_t _processFRSemaphore;
    dispatch_semaphore_t _processLivenessSemaphore;
    
}
@property (nonatomic, assign) BOOL              frModelVersionChecked;
@property (nonatomic, strong) ASFRManager*       frManager;
@property (atomic, strong) ASFRPerson*           frPerson;
@property (nonatomic, strong) dispatch_queue_t   screenFlashSerialQueue;

@property (nonatomic, strong) ArcSoftFaceEngine*      arcsoftFace;
@end

@implementation ASFVideoProcessor

- (instancetype)init {
    self = [super init];
    if(self) {
        _processSemaphore = NULL;
        _processFRSemaphore = NULL;
    }
    return self;
}

- (void)initProcessor
{
    self.arcsoftFace = [[ArcSoftFaceEngine alloc] init];
    MRESULT mr = [self.arcsoftFace initFaceEngineWithDetectMode:DETECT_MODE
                                            orientPriority:ASF_OP_0_ONLY
                                                maxFaceNum:ASF_FACE_NUM
                                              combinedMask:ASF_FACE_COMBINEDMASK];
    if (mr == MOK) {
        NSLog(@"初始化成功");
    } else {
        NSLog(@"初始化失败：%ld", mr);
    }
    
    _processSemaphore = dispatch_semaphore_create(1);
    _processFRSemaphore = dispatch_semaphore_create(1);
    _processLivenessSemaphore = dispatch_semaphore_create(1);
    self.screenFlashSerialQueue = dispatch_queue_create("com.example.serialQueue", DISPATCH_QUEUE_SERIAL);
    self.frManager = [[ASFRManager alloc] init];
}

- (void)uninitProcessor
{
    NSLog(@"wait processSem");
    if(_processSemaphore && 0 == dispatch_semaphore_wait(_processSemaphore, DISPATCH_TIME_FOREVER))
    {
        dispatch_semaphore_signal(_processSemaphore);
        _processSemaphore = NULL;
    }
    NSLog(@"wait livenessSem");
    if(_processLivenessSemaphore && 0 == dispatch_semaphore_wait(_processLivenessSemaphore, DISPATCH_TIME_FOREVER))
    {
        dispatch_semaphore_signal(_processLivenessSemaphore);
        _processLivenessSemaphore = NULL;
    }
    NSLog(@"wait frSem");
    if(_processFRSemaphore && 0 == dispatch_semaphore_wait(_processFRSemaphore, DISPATCH_TIME_FOREVER))
    {
        [Utility freeCameraData:_cameraDataForProcessFR];
        _cameraDataForProcessFR = MNull;
        
        dispatch_semaphore_signal(_processFRSemaphore);
        _processFRSemaphore = NULL;
    }
    NSLog(@"wait frSem over");
    [self.arcsoftFace unInitFaceEngine];
    self.arcsoftFace = nil;
}

- (void)setDetectFaceUseFD:(BOOL)detectFaceUseFD
{
    if(_detectFaceUseFD == detectFaceUseFD)
        return;
    _detectFaceUseFD = detectFaceUseFD;
    
    [self uninitProcessor];
    [self initProcessor];
}

- (BOOL)isDetectFaceUseFD
{
    return _detectFaceUseFD;
}

-(NSInteger)actionDetect:(ASF_CAMERA_DATA*)cameraData
                  action:(int)action
                isReset:(int)reset
{
    
    
    int ret = -1;
    NSLog(@"screenFlashDetect func start");
    if(0 == dispatch_semaphore_wait(_processSemaphore, 0))
    {
        NSLog(@"screenFlashDetect func ing");
        __block ASF_SingleFaceInfo singleFaceInfo = {0};
       
        do {
            ASF_MultiFaceInfo multiFaceInfo = {0};
            MRESULT mr = [self.arcsoftFace detectFacesWithWidth:cameraData->i32Width
                                                         height:cameraData->i32Height
                                                           data:cameraData->ppu8Plane[0]
                                                         format:cameraData->u32PixelArrayFormat
                                                        faceRes:&multiFaceInfo];
            if(MOK != mr || multiFaceInfo.faceNum == 0) {
                //NSLog(@"FD结果：%ld", mr);
                dispatch_semaphore_signal(_processSemaphore);
                break;
            }
            int faceArea = 0;
            int maxFaceIndex = 0;
            NSLog(@"detect face num:%d", multiFaceInfo.faceNum);
            for (int face=0; face<multiFaceInfo.faceNum; face++)
            {
                ASFVideoFaceInfo *faceInfo = [[ASFVideoFaceInfo alloc] init];
                faceInfo.faceRect = multiFaceInfo.faceRect[face];
                if(faceInfo.faceRect.left >= 0 && faceInfo.faceRect.right >=0
                   && faceInfo.faceRect .top >= 0 && faceInfo.faceRect .bottom >=0)
                {
                    int currFaceArea = (faceInfo.faceRect.right - faceInfo.faceRect.left) * (faceInfo.faceRect.bottom - faceInfo.faceRect.top);
                    if(currFaceArea > faceArea)
                    {
                        maxFaceIndex = face;
                        faceArea = currFaceArea;
                    }
                }
                
            }
            ret = 0;
            singleFaceInfo.faceRect = multiFaceInfo.faceRect[maxFaceIndex];
            singleFaceInfo.faceOrient = multiFaceInfo.faceOrient[maxFaceIndex];
            singleFaceInfo.faceDataInfo = multiFaceInfo.faceDataInfoList[maxFaceIndex];
            
           
            __block ASF_CAMERA_INPUT_DATA offscreenProcess = [self copyCameraDataForProcessFR:cameraData];
            __block int currentAction = action;
            __block int isActionReset = reset;
            dispatch_semaphore_signal(_processSemaphore);
            //这里做交互式活体检测
            if(0 == dispatch_semaphore_wait(_processLivenessSemaphore, 0))
            {
                    dispatch_async(self.screenFlashSerialQueue, ^(){
                    
                    ASF_LivenessResult livenessRes = {0};
                    NSLog(@"detectLivenessInteractiveWithWidth start");
                    MRESULT mr = [self.arcsoftFace detectLivenessInteractiveWithWidth:offscreenProcess->i32Width
                                                                               height:offscreenProcess->i32Height
                                                                               format:offscreenProcess->u32PixelArrayFormat
                                                                               data:offscreenProcess->ppu8Plane[0]
                                                                               singleFaceInfo:&singleFaceInfo
                                                                               action:currentAction
                                                                                resetOpt:isActionReset
                                                                                livenessResult:&livenessRes];
                        NSLog(@"detectLivenessInteractiveWithWidth end");
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            NSLog(@"updateLivenessResult 11111111111");
                            if(self.flashDelegate && [self.flashDelegate respondsToSelector:@selector(showLiveneeTips:)])
                            {
                                NSLog(@"updateLivenessResult start");
                                [self.flashDelegate updateLivenessResult:mr livenessRes:livenessRes.iRes];
                                NSLog(@"updateLivenessResult end");
                            }
                               
                        });
                        
                   
                    NSLog(@"liveness res:%d", livenessRes.iRes);
                    dispatch_semaphore_signal(_processLivenessSemaphore);
                });
            }
            
        } while (0);
    }
    
    return ret;
    
  
    
}
-(NSInteger)screenFlashDetect:(ASF_CAMERA_DATA*)cameraData
                    flashOrder:(ASF_ColorCode)order
                   flashColor:(ASF_FlashColor)color
                    isReset:(int)reset
                    isLastFrame:(bool)lastFrame
{
    int ret = -1;
    NSLog(@"screenFlashDetect func start");
    if(0 == dispatch_semaphore_wait(_processLivenessSemaphore, 0))
    {
        NSLog(@"screenFlashDetect func ing");
        __block ASF_SingleFaceInfo singleFaceInfo = {0};
       
        do {
            ASF_MultiFaceInfo multiFaceInfo = {0};
            MRESULT mr = [self.arcsoftFace detectFacesWithWidth:cameraData->i32Width
                                                         height:cameraData->i32Height
                                                           data:cameraData->ppu8Plane[0]
                                                         format:cameraData->u32PixelArrayFormat
                                                        faceRes:&multiFaceInfo];
            if(MOK != mr || multiFaceInfo.faceNum == 0) {
                //NSLog(@"FD结果：%ld", mr);
                break;
            }
            int faceArea = 0;
            int maxFaceIndex = 0;
            NSLog(@"detect face num:%d", multiFaceInfo.faceNum);
            for (int face=0; face<multiFaceInfo.faceNum; face++)
            {
                ASFVideoFaceInfo *faceInfo = [[ASFVideoFaceInfo alloc] init];
                faceInfo.faceRect = multiFaceInfo.faceRect[face];
                if(faceInfo.faceRect.left >= 0 && faceInfo.faceRect.right >=0
                   && faceInfo.faceRect .top >= 0 && faceInfo.faceRect .bottom >=0)
                {
                    int currFaceArea = (faceInfo.faceRect.right - faceInfo.faceRect.left) * (faceInfo.faceRect.bottom - faceInfo.faceRect.top);
                    if(currFaceArea > faceArea)
                    {
                        maxFaceIndex = face;
                        faceArea = currFaceArea;
                    }
                }
                
            }
            
            singleFaceInfo.faceRect = multiFaceInfo.faceRect[maxFaceIndex];
            singleFaceInfo.faceOrient = multiFaceInfo.faceOrient[maxFaceIndex];
            singleFaceInfo.faceDataInfo = multiFaceInfo.faceDataInfoList[maxFaceIndex];
            
            __block ASF_CAMERA_INPUT_DATA offscreenProcess = [self copyCameraDataForProcessFR:cameraData];
            __block ScreenFlashInfo screenFlashInfo = {0};
            screenFlashInfo.color = color;
            screenFlashInfo.reset = reset;
            screenFlashInfo.order = order;
            screenFlashInfo.lastFrame = lastFrame;
            ret = 0;//运行到这说明人脸是OK的，可以等待下一个颜色处理
            //这里做交互式活体检测
            dispatch_async(self.screenFlashSerialQueue, ^(){
            ASF_LivenessResult livenessRes = {0};
            [self.arcsoftFace detectLivenessGlareWithWidth:offscreenProcess->i32Width
                                                    height:offscreenProcess->i32Height
                                                    format:offscreenProcess->u32PixelArrayFormat
                                                    data:offscreenProcess->ppu8Plane[0]
                                                    singleFaceInfo:&singleFaceInfo
                                                    flashSequence:screenFlashInfo.order
                                                    color:screenFlashInfo.color
                                                    resetOpt:screenFlashInfo.reset
                                                    livenessResult:&livenessRes];
             if(screenFlashInfo.lastFrame)
             {
                 //更新UI显示
                 NSLog(@"liveness res:%d", livenessRes.iRes);
                 dispatch_sync(dispatch_get_main_queue(), ^{
                     if(self.flashDelegate && [self.flashDelegate respondsToSelector:@selector(showLiveneeTips:)])
                     {
                         NSString* tips = @"";
                         if(1 == livenessRes.iRes)
                         {
                             tips = @"活体检测结果：活体";
                         }
                         else
                         {
                             tips = @"活体检测结果：非活体";
                         }
                         [self.flashDelegate showLiveneeTips:tips];
                     }
                        
                 });
             }
            NSLog(@"liveness res:%d", livenessRes.iRes);
            });
            
        } while (0);
        dispatch_semaphore_signal(_processLivenessSemaphore);
    }
    
    return ret;
}
- (NSArray*)process:(ASF_CAMERA_DATA*)cameraData
{
    NSMutableArray *arrayFaceInfo = nil;
    if(0 == dispatch_semaphore_wait(_processSemaphore, 0))
    {
        __block BOOL detectFace = NO;
        __block ASF_SingleFaceInfo singleFaceInfo = {0};
        __weak ASFVideoProcessor* weakSelf = self;
        
        do {
            ASF_MultiFaceInfo multiFaceInfo = {0};
            MRESULT mr = [self.arcsoftFace detectFacesWithWidth:cameraData->i32Width
                                                         height:cameraData->i32Height
                                                           data:cameraData->ppu8Plane[0]
                                                         format:cameraData->u32PixelArrayFormat
                                                        faceRes:&multiFaceInfo];
            if(MOK != mr || multiFaceInfo.faceNum == 0) {
                //NSLog(@"FD结果：%ld", mr);
                break;
            }	
            
            arrayFaceInfo = [NSMutableArray arrayWithCapacity:0];
            for (int face=0; face<multiFaceInfo.faceNum; face++) {
                ASFVideoFaceInfo *faceInfo = [[ASFVideoFaceInfo alloc] init];
                faceInfo.faceRect = multiFaceInfo.faceRect[face];
                [arrayFaceInfo addObject:faceInfo];
            }
            
            detectFace = YES;
            singleFaceInfo.faceRect = multiFaceInfo.faceRect[0];
            singleFaceInfo.faceOrient = multiFaceInfo.faceOrient[0];
            singleFaceInfo.faceDataInfo = multiFaceInfo.faceDataInfoList[0];
            NSTimeInterval begin = [[NSDate date] timeIntervalSince1970];
            mr = [self.arcsoftFace processWithWidth:cameraData->i32Width
                                             height:cameraData->i32Height
                                               data:cameraData->ppu8Plane[0]
                                             format:cameraData->u32PixelArrayFormat
                                            faceRes:&multiFaceInfo
                                               mask: ASF_AGE | ASF_GENDER | ASF_LIVENESS];
            NSTimeInterval cost = [[NSDate date] timeIntervalSince1970] - begin;
            //NSLog(@"processTime=%dms", (int)(cost * 1000));
            if(MOK != mr) {
                NSLog(@"process失败：%ld", mr);
                break;
            }
            
            ASF_AgeInfo ageInfo = {0};
            if(MOK != [self.arcsoftFace getAge:&ageInfo] || ageInfo.num != multiFaceInfo.faceNum)
                break;
            
            ASF_GenderInfo genderInfo = {0};
            if(MOK != [self.arcsoftFace getGender:&genderInfo] || genderInfo.num != multiFaceInfo.faceNum)
                break;
            
            ASF_LivenessInfo livenessInfo = {0};
            if(MOK != [self.arcsoftFace getLiveness:&livenessInfo] || livenessInfo.num != multiFaceInfo.faceNum)
                break;
            
            for (int face=0; face<multiFaceInfo.faceNum; face++) {
                ASFFace3DAngle *face3DAngleInfo = [[ASFFace3DAngle alloc] init];
                face3DAngleInfo.yawAngle = multiFaceInfo.face3DAngleInfo.yaw[face];
                face3DAngleInfo.pitchAngle = multiFaceInfo.face3DAngleInfo.pitch[face];
                face3DAngleInfo.rollAngle = multiFaceInfo.face3DAngleInfo.roll[face];
                
                ASFVideoFaceInfo *faceInfo = arrayFaceInfo[face];
                faceInfo.face3DAngle = face3DAngleInfo;
                faceInfo.age = ageInfo.ageArray[face];
                faceInfo.gender = genderInfo.genderArray[face];
                faceInfo.liveness = livenessInfo.isLive[face];
            }
        } while (NO);
        
        dispatch_semaphore_signal(_processSemaphore);

        if(0 == dispatch_semaphore_wait(_processFRSemaphore, 0))
        {
            __block ASF_CAMERA_INPUT_DATA offscreenProcess = [self copyCameraDataForProcessFR:cameraData];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
                
                if(!weakSelf.frModelVersionChecked)
                {
                    weakSelf.frModelVersionChecked = YES;
                }
                
                if(detectFace)
                {
                    ASF_FaceFeature faceFeature = {0};
                    NSTimeInterval begin = [[NSDate date] timeIntervalSince1970];
                    MRESULT mr = [self.arcsoftFace extractFaceFeatureWithWidth:offscreenProcess->i32Width
                                                                        height:offscreenProcess->i32Height
                                                                          data:offscreenProcess->ppu8Plane[0]
                                                                        format:offscreenProcess->u32PixelArrayFormat
                                                                      faceInfo:&singleFaceInfo
                                                                       feature:&faceFeature];
                    NSTimeInterval cost = [[NSDate date] timeIntervalSince1970] - begin;
                    //NSLog(@"FRTime=%dms", (int)(cost * 1000));
                    if(mr == MOK)
                    {
                        ASFRPerson* currentPerson = [[ASFRPerson alloc] init];
                        currentPerson.faceFeatureData =
                        [NSData dataWithBytes:faceFeature.feature
                                       length:faceFeature.featureSize];
                        NSArray* persons = self.frManager.allPersons;
                        NSString* recognizedName = nil;
                        float maxScore = 0.0;
                        for (ASFRPerson* person in persons)
                        {
                            ASF_FaceFeature refFaceFeature = {0};
                            refFaceFeature.feature = (MByte*)[person.faceFeatureData bytes];
                            refFaceFeature.featureSize = (MInt32)[person.faceFeatureData length];
                            
                            MFloat fConfidenceLevel =  0.0;
                            MRESULT mr = [self.arcsoftFace compareFaceWithFeature:&faceFeature
                                                                         feature2:&refFaceFeature
                                                                        confidenceLevel:&fConfidenceLevel];
                            NSLog(@"compareFeature:similar=%.2f", fConfidenceLevel);
                            if (mr == MOK && fConfidenceLevel >= maxScore) {
                                maxScore = fConfidenceLevel;
                                recognizedName = person.name;
                            }
                        }
                        
                        MFloat scoreThreshold = 0.81;
                        if (maxScore > scoreThreshold) {
                            currentPerson.name = recognizedName;
                        }
                        
                        self.frPerson = currentPerson;
                    }
                    else
                    {
                        self.frPerson = nil;
                    }
                }
                else
                {
                    self.frPerson = nil;
                }
                dispatch_semaphore_signal(_processFRSemaphore);
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if(self.delegate && [self.delegate respondsToSelector:@selector(processRecognized:)])
                        [self.delegate processRecognized:self.frPerson.name];
                });
            });
        }
    }

    return arrayFaceInfo;
}

- (BOOL)registerDetectedPerson:(NSString *)personName
{
    ASFRPerson *registerPerson = self.frPerson;
    if(registerPerson == nil || registerPerson.registered)
        return NO;
    
    registerPerson.name = personName;
    registerPerson.Id = [self.frManager getNewPersonID];
    registerPerson.registered = [self.frManager addPerson:registerPerson];

    return registerPerson.registered;
}

- (ASF_CAMERA_INPUT_DATA)copyCameraDataForProcessFR:(ASF_CAMERA_INPUT_DATA)pOffscreenIn
{
    if (pOffscreenIn == MNull) {
        return  MNull;
    }
    
    if (_cameraDataForProcessFR != NULL)
    {
        if (_cameraDataForProcessFR->i32Width != pOffscreenIn->i32Width ||
            _cameraDataForProcessFR->i32Height != pOffscreenIn->i32Height ||
            _cameraDataForProcessFR->u32PixelArrayFormat != pOffscreenIn->u32PixelArrayFormat) {
            [Utility freeCameraData:_cameraDataForProcessFR];
            _cameraDataForProcessFR = NULL;
        }
    }
    
    if (_cameraDataForProcessFR == NULL) {
        _cameraDataForProcessFR = [Utility createOffscreen:pOffscreenIn->i32Width
                                                   height:pOffscreenIn->i32Height
                                                   format:pOffscreenIn->u32PixelArrayFormat];
    }
    
    if (ASVL_PAF_NV12 == pOffscreenIn->u32PixelArrayFormat)
    {
        memcpy(_cameraDataForProcessFR->ppu8Plane[0],
               pOffscreenIn->ppu8Plane[0],
               pOffscreenIn->i32Height * pOffscreenIn->pi32Pitch[0]) ;
        
        memcpy(_cameraDataForProcessFR->ppu8Plane[1],
               pOffscreenIn->ppu8Plane[1],
               pOffscreenIn->i32Height * pOffscreenIn->pi32Pitch[1] / 2);
    }
    
    return _cameraDataForProcessFR;
}
@end
