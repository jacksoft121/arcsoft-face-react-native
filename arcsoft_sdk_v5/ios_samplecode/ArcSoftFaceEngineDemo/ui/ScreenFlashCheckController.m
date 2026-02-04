//
//  ScreenFlashCheckController.m
//  ArcSoftFaceEngineDemo
//
//  Created by arc-mac-m4 on 2025/10/30.
//  Copyright © 2025 ArcSoft. All rights reserved.
//

#import "ScreenFlashCheckController.h"
#import "ASFCameraController.h"
#import "MetalView.h"
#import "ASFVideoProcessor.h"
#import "Utility.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>

NS_ASSUME_NONNULL_BEGIN

#define IMAGE_WIDTH 720
#define IMAGE_HEIGHT 1280

@interface ScreenFlashStat:NSObject
@property(nonatomic,assign) bool isFlashIng;

@property(nonatomic,assign) int color;
@property(nonatomic,assign) int colorIndex;
@property(nonatomic,assign) int flashOrder;
@property(nonatomic,assign) bool hasInit;
@property (nonatomic, assign) CFAbsoluteTime colorStartTime;

@property(nonatomic,assign) bool isActionDetectIng;
@property(nonatomic,assign) int actionIndex;
@property(nonatomic,strong) NSMutableArray *actionGroup;

@end

@implementation ScreenFlashStat
@end

@interface ScreenFlashCheckController()<ASFCameraControllerDelegate, ASFVideoFlashLivenessDelegate>

@property (nonatomic, strong) ASFCameraController *cameraController;
@property (nonatomic, strong) ASFVideoProcessor *videoProcessor;
@property (nonatomic, strong) NSMutableArray *arrayAllFaceRectView;
@property (weak, nonatomic) IBOutlet UIButton *actionLivenessCheck;
@property (weak, nonatomic) IBOutlet UIButton *flashLivenessCheck;
@property (weak, nonatomic) IBOutlet MetalView  *metalView;

@property (nonatomic, strong) UIView *flashOverlayView;
@property (nonatomic, strong) dispatch_queue_t flashQueue;
@property (nonatomic, strong) ScreenFlashStat *screenFlashStat;
// 属性：记录原亮度
@property (nonatomic, assign) CGFloat originalBrightness;

@property (nonatomic, strong) NSDictionary *colorMap;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) NSTimer *tipsShowTimer;

@property (weak, nonatomic) IBOutlet UIButton *backBtn;

@property (nonatomic, strong) NSTimer *actionDetectTimer;

@property (nonatomic, strong) dispatch_queue_t processingQueue;//用来处理画面水平翻转

@property (nonatomic, strong) CIContext *ciContext;

@property (nonatomic, assign)BOOL maskAdded;
@end

@implementation ScreenFlashCheckController

-(void)clearScreenFlashStat
{
    self.screenFlashStat.isFlashIng = false;
    self.screenFlashStat.colorIndex = 0;
    self.screenFlashStat.hasInit = false;
    self.screenFlashStat.color = 0;
    self.screenFlashStat.flashOrder = 0;
    self.screenFlashStat.isActionDetectIng = false;
    self.screenFlashStat.actionIndex = 0;
    [self.screenFlashStat.actionGroup removeAllObjects];
}
- (IBAction)actionLivenessDeal:(id)sender
{
   //随机生成一组动作
    self.actionLivenessCheck.enabled =NO;
    self.actionLivenessCheck.alpha = 0.5;
    self.flashLivenessCheck.enabled =NO;
    self.flashLivenessCheck.alpha = 0.5;
    
    NSLog(@"actionLivenessDeal");
    [self clearScreenFlashStat];
    NSMutableArray *arrayAction = [NSMutableArray array];
    [arrayAction addObject:@(ASF_ACTION_TYPE_EB)];
    [arrayAction addObject:@(ASF_ACTION_TYPE_MO)];
    [arrayAction addObject:@(ASF_ACTION_TYPE_HL)];
    [arrayAction addObject:@(ASF_ACTION_TYPE_HR)];
    
    int actionIndex = arc4random_uniform(4); // 随机 0~3
    [self.screenFlashStat.actionGroup addObject:arrayAction[actionIndex]];
    [arrayAction removeObjectAtIndex:actionIndex];
    actionIndex = arc4random_uniform(3);
    [self.screenFlashStat.actionGroup addObject:arrayAction[actionIndex]];
    self.screenFlashStat.isActionDetectIng = true;
    self.screenFlashStat.actionIndex = 0;
    
    NSNumber *nsAction = self.screenFlashStat.actionGroup[0];
    int action0 = [nsAction intValue];
    
    nsAction = self.screenFlashStat.actionGroup[1];
    int action1 = [nsAction intValue];
    
    
    NSLog(@"Action group:%d %d", action0, action1);
    [self singleActionTimeOutDeal];
}
-(void)singleActionTimeOutDeal
{
    if (self.actionDetectTimer)
    {
        [self.actionDetectTimer invalidate];
        self.actionDetectTimer = nil;

    }
    self.actionDetectTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                      repeats:NO
                                                        block:^(NSTimer * _Nonnull timer) {
        [self showLiveneeTips:@"检测超时"];
        [self clearScreenFlashStat];
        self.actionLivenessCheck.enabled =YES;
        self.actionLivenessCheck.alpha = 1.0;
        self.flashLivenessCheck.enabled =YES;
        self.flashLivenessCheck.alpha = 1.0;
    }];
}
- (NSArray<UIColor *> *)generateRandomFlashColors
{
    ASF_ColorCode colorCode = arc4random_uniform(3); // 随机 0~2

    NSLog(@"随机颜色序列类型: %d", colorCode);
    self.screenFlashStat.flashOrder = colorCode;
    UIColor *white = [UIColor colorWithWhite:1.0 alpha:1.0];
    UIColor *red   = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    UIColor *green = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    UIColor *blue  = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0];
    UIColor *pink  = [UIColor colorWithRed:1.0 green:0.0 blue:1.0 alpha:1.0];
    UIColor *yellow= [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:1.0];

    NSArray<UIColor *> *flashColors = nil;
    switch (colorCode) {
        case ASF_WRGB:
            flashColors = @[white, red, green, blue];
            break;
        case ASF_WRGP:
            flashColors = @[white, red, green, pink];
            break;
        case ASF_WRGY:
            flashColors = @[white, red, green, yellow];
            break;
        default:
            flashColors = @[white, red, green, blue];
            break;
    }

    return flashColors;
}
- (IBAction)screenFlashLivenessDeal:(id)sender
{
    NSLog(@"flash detect");
    self.actionLivenessCheck.enabled =NO;
    self.actionLivenessCheck.alpha = 0.5;
    self.flashLivenessCheck.enabled =NO;
    self.flashLivenessCheck.alpha = 0.5;
    // 记录当前亮度
    self.originalBrightness = [UIScreen mainScreen].brightness;
        
        // 提亮屏幕
    [UIScreen mainScreen].brightness = 1.0;
 
    NSArray<UIColor *> *flashColors = [self generateRandomFlashColors];
    self.screenFlashStat.isFlashIng = true;
    self.screenFlashStat.colorIndex = 0;
    self.screenFlashStat.hasInit = false;
    self.screenFlashStat.color = 0;
    self.screenFlashStat.flashOrder = 0;
       dispatch_async(self.flashQueue, ^{
           for (UIColor *color in flashColors) {
               
               NSArray *colorSeq = self.colorMap[@(self.screenFlashStat.flashOrder)];
               NSNumber *nsColor  = colorSeq[self.screenFlashStat.colorIndex];
               self.screenFlashStat.color = [nsColor intValue];
               self.screenFlashStat.colorStartTime = CFAbsoluteTimeGetCurrent();
               NSLog(@"screen flash color:%d", self.screenFlashStat.color);
               dispatch_sync(dispatch_get_main_queue(), ^{
                   [self flashOutsideCircleWithColor:color duration:0.3];
               });
               
               [NSThread sleepForTimeInterval:0.35]; // 每个颜色间隔 0.6s
               self.screenFlashStat.colorIndex++;
           }

           // 恢复原亮度
          dispatch_async(dispatch_get_main_queue(), ^{
              [UIScreen mainScreen].brightness = self.originalBrightness;
              self.screenFlashStat.isFlashIng = false;
              self.actionLivenessCheck.enabled =YES;
              self.actionLivenessCheck.alpha = 1.0;
              self.flashLivenessCheck.enabled =YES;
              self.flashLivenessCheck.alpha = 1.0;
          });
       });
}

// 闪光函数：color为闪光颜色
- (void)flashOutsideCircleWithColor:(UIColor *)color duration:(NSTimeInterval)duration {
    self.flashOverlayView.backgroundColor = color;
        self.flashOverlayView.alpha = 0.0;

        CGRect bounds = [UIScreen mainScreen].bounds;
        CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
        CGFloat radius = MIN(bounds.size.width, bounds.size.height) * 0.25;

        UIBezierPath *path = [UIBezierPath bezierPathWithRect:bounds];
        [path appendPath:[UIBezierPath bezierPathWithArcCenter:center
                                                        radius:radius
                                                    startAngle:0
                                                      endAngle:M_PI * 2
                                                     clockwise:YES]];

        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.path = path.CGPath;
        maskLayer.fillRule = kCAFillRuleEvenOdd;
        self.flashOverlayView.layer.mask = maskLayer;

        [UIView animateWithDuration:duration animations:^{
            self.flashOverlayView.alpha = 1.0;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:duration animations:^{
                self.flashOverlayView.alpha = 0.0;
            }];
        }];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.arrayAllFaceRectView = [NSMutableArray arrayWithCapacity:0];
    
    self.videoProcessor = [[ASFVideoProcessor alloc] init];
    self.videoProcessor.flashDelegate = self;
    [self.videoProcessor initProcessor];
    
    self.cameraController = [[ASFCameraController alloc] init];
    self.cameraController.delegate = self;
    UIInterfaceOrientation uiOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self.cameraController setupCaptureSession:(AVCaptureVideoOrientation)uiOrientation];
    
    self.screenFlashStat = [[ScreenFlashStat alloc] init];
    
    // ✅ 设置为 4:3 模式（仅这个界面）
    [self.cameraController setAspectRatio:@"4:3"];
    
    
    // 获取逻辑分辨率（pt）
    CGSize logicalSize = [UIScreen mainScreen].bounds.size;
    NSLog(@"逻辑分辨率: %.0f × %.0f pt", logicalSize.width, logicalSize.height);

    // 获取缩放因子
    CGFloat scale = [UIScreen mainScreen].scale;
    NSLog(@"屏幕 scale: %.1f", scale);

    // 获取物理分辨率（px）
    CGSize physicalSize = CGSizeMake(logicalSize.width * scale,
                                     logicalSize.height * scale);
    NSLog(@"物理分辨率: %.0f × %.0f px", physicalSize.width, physicalSize.height);

    // ===== 按钮样式美化 =====
   [self setupButtonStyle:self.actionLivenessCheck title:@"开始交互式活体检测"];
   [self setupButtonStyle:self.flashLivenessCheck title:@"开始炫光活体检测"];
   [self setupButtonStyle:self.backBtn title:@"返回"];
    self.actionLivenessCheck.translatesAutoresizingMaskIntoConstraints = NO;
    self.flashLivenessCheck.translatesAutoresizingMaskIntoConstraints = NO;
    self.backBtn.translatesAutoresizingMaskIntoConstraints = NO;
    
    CGFloat buttonWidth = 180;
    CGFloat buttonHeight = 44;
    CGFloat spacing = 20;

    [NSLayoutConstraint activateConstraints:@[
        // 第一个按钮
        [self.actionLivenessCheck.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.actionLivenessCheck.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-140],
        [self.actionLivenessCheck.widthAnchor constraintEqualToConstant:buttonWidth],
        [self.actionLivenessCheck.heightAnchor constraintEqualToConstant:buttonHeight],
        
        // 第二个按钮
        [self.flashLivenessCheck.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.flashLivenessCheck.topAnchor constraintEqualToAnchor:self.actionLivenessCheck.bottomAnchor constant:spacing],
        [self.flashLivenessCheck.widthAnchor constraintEqualToAnchor:self.actionLivenessCheck.widthAnchor],
        [self.flashLivenessCheck.heightAnchor constraintEqualToAnchor:self.actionLivenessCheck.heightAnchor],
        
        //
        // 第三个按钮
        // 顶部距离安全区域 20pt
       [self.backBtn.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
       // 左边距离屏幕左边缘 20pt
       [self.backBtn.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
       // 宽度和高度	
       [self.backBtn.widthAnchor constraintEqualToConstant:100],
       [self.backBtn.heightAnchor constraintEqualToConstant:44]
        
    ]];

    //创建提示文本
      self.titleLabel = [[UILabel alloc] init];
      self.titleLabel.text = @"";
      self.titleLabel.textColor = [UIColor blackColor];
      self.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightMedium];
      self.titleLabel.textAlignment = NSTextAlignmentCenter;
      
      [self.view addSubview:self.titleLabel];
      
      self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
      [NSLayoutConstraint activateConstraints:@[
          [self.titleLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:100],
          [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
          [self.titleLabel.widthAnchor constraintEqualToConstant:250],
          [self.titleLabel.heightAnchor constraintEqualToConstant:40]
      ]];
    self.screenFlashStat.actionGroup = [NSMutableArray array];
    
    self.flashOverlayView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.flashOverlayView.backgroundColor = [UIColor clearColor];
    self.flashOverlayView.userInteractionEnabled = NO;
    [self.view addSubview:self.flashOverlayView];
    [self.view bringSubviewToFront:self.metalView];
    self.maskAdded = NO;
    
    self.flashQueue = dispatch_queue_create("com.example.flashQueue", DISPATCH_QUEUE_SERIAL);
    
    // 初始化串行处理队列
    self.processingQueue = dispatch_queue_create("com.example.flipProcessingQueue", DISPATCH_QUEUE_SERIAL);
    
    // 初始化 CIContext，使用 Metal 提高 GPU 性能
    self.ciContext = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer: @NO}];
    
    self.colorMap = @{
        @(ASF_WRGB): @[@(ASF_COLOR_WHITE), @(ASF_COLOR_RED), @(ASF_COLOR_GREEN), @(ASF_COLOR_BLUE)],
        @(ASF_WRGP): @[@(ASF_COLOR_WHITE), @(ASF_COLOR_RED), @(ASF_COLOR_GREEN), @(ASF_COLOR_PINK)],
        @(ASF_WRGY): @[@(ASF_COLOR_WHITE), @(ASF_COLOR_RED), @(ASF_COLOR_GREEN), @(ASF_COLOR_YELLOW)]
    };
    
    for (NSLayoutConstraint *c in self.view.constraints) {
        NSLog(@"约束: %@", c);
    }}
- (void)dealloc {
    NSLog(@"%@ 被销毁了", NSStringFromClass([self class]));
}
- (void)setupButtonStyle:(UIButton *)button title:(NSString *)title {
    [button setTitle:title forState:UIControlStateNormal];
    
    // 填充背景
    button.backgroundColor = [UIColor colorWithRed:0.12 green:0.56 blue:1.0 alpha:1.0]; // 系统蓝
    
    // 圆角
    button.layer.cornerRadius = 10.0;
    button.layer.masksToBounds = YES;
    
    // 字体
    button.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    // 阴影（可选）
    button.layer.shadowColor = [UIColor blackColor].CGColor;
    button.layer.shadowOpacity = 0.15;
    button.layer.shadowOffset = CGSizeMake(0, 2);
    button.layer.shadowRadius = 4;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.cameraController startCaptureSession];
        
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"Screen flash viewWillDisappear");
    [super viewWillDisappear:animated];
//    if(self.cameraController)
//    {
//        [self.cameraController stopCaptureSession];
//    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if(self.cameraController)
        {
            [self.cameraController stopCaptureSession];
            self.cameraController = nil;
           
        }
        if(self.videoProcessor)
        {
            [self.videoProcessor uninitProcessor];
            self.videoProcessor = nil;
        }
        
    });
    
}
- (IBAction)cancel:(id)sender {

    NSLog(@"Screen flash cancel");
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.flashOverlayView.frame = [UIScreen mainScreen].bounds;

    if (!self.maskAdded)
    {
        self.maskAdded = YES;
        
        // 圆的直径：屏幕宽度的一半
           CGFloat diameter = [UIScreen mainScreen].bounds.size.width / 2.0;
           
           // metalView 采用 4:3 比例，高为圆的直径
           CGFloat metalViewHeight = diameter * 4.0 / 3.0;
           CGFloat metalViewWidth  = diameter ;
           
           // 居中对齐（保持圆的中心在屏幕中心）
           CGFloat x = (self.view.bounds.size.width - metalViewWidth) / 2.0;
           CGFloat y = (self.view.bounds.size.height - metalViewHeight) / 2.0;
           self.metalView.frame = CGRectMake(x, y, metalViewWidth, metalViewHeight);
           
           // 在 metalView 内绘制圆形遮罩
           CGFloat circleX = (metalViewWidth - diameter) / 2.0;
           CGFloat circleY = (metalViewHeight - diameter) / 2.0;
           CGRect circleRect = CGRectMake(circleX, circleY, diameter, diameter);
           
           // 圆形遮罩路径
           UIBezierPath *circlePath = [UIBezierPath bezierPathWithOvalInRect:circleRect];
        
        // 遮罩层
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.path = circlePath.CGPath;
        self.metalView.layer.mask = maskLayer;
        
        // 白色边框圈（非遮罩）
        CAShapeLayer *borderLayer = [CAShapeLayer layer];
        borderLayer.path = circlePath.CGPath;
        borderLayer.fillColor = [UIColor clearColor].CGColor;
        borderLayer.strokeColor = [UIColor whiteColor].CGColor;
        borderLayer.lineWidth = 2.0;
        borderLayer.frame = self.metalView.bounds;
        [self.metalView.layer addSublayer:borderLayer];
        
       
        
    }
    

}

-(void)screenFlashCaptureDeal:(CMSampleBufferRef)sampleBuffer
{
    static int lastDealColor = 0;
    ASF_CAMERA_DATA* cameraData = [Utility getCameraDataFromSampleBuffer:sampleBuffer];
    do {
        
        NSLog(@"Flash detect ing");
        CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
        CFAbsoluteTime delta = now - self.screenFlashStat.colorStartTime;
        if(!self.screenFlashStat.hasInit)
        {
            NSInteger res = [self.videoProcessor screenFlashDetect:cameraData flashOrder:self.screenFlashStat.flashOrder flashColor:self.screenFlashStat.color isReset:1 isLastFrame:false];
            if(res != 0)
            {
                NSLog(@"Flash detect init failed");
                dispatch_sync(dispatch_get_main_queue(), ^{
                    NSString* tips = @"未检测到人脸";
                    [self showLiveneeTips:tips];
                });
                
                break;
            }
            NSLog(@"Flash detect init");
            self.screenFlashStat.hasInit = true;
            break;
        }
        if(lastDealColor == self.screenFlashStat.color)
        {
            break;
        }
       
        if(delta >= 0.15 && delta < 0.20)
        {
            bool isLastFrame = false;
            if(3 == self.screenFlashStat.colorIndex)
            {
                isLastFrame = true;
            }
            NSInteger res = [self.videoProcessor screenFlashDetect:cameraData flashOrder:self.screenFlashStat.flashOrder flashColor:self.screenFlashStat.color isReset:0 isLastFrame:isLastFrame];
            if(res == 0)
            {
                lastDealColor = self.screenFlashStat.color;
            }
        }
       
    } while (0);
    [Utility freeCameraData:cameraData];
}


-(void)actionCaptureDeal:(CMSampleBufferRef)sampleBuffer
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (!pixelBuffer) return;

    ASF_CAMERA_DATA* cameraDataAction = [Utility getCameraDataFromSampleBuffer:sampleBuffer];
    
    NSLog(@"Action detect ing");
    int index = self.screenFlashStat.actionIndex;
    NSNumber *nsAction = self.screenFlashStat.actionGroup[index];
    int action = [nsAction intValue];
    NSLog(@"Current action is :%d", action);
    do {
        if(!self.screenFlashStat.hasInit)
        {
            NSInteger res = [self.videoProcessor actionDetect:cameraDataAction action:action isReset:1];
            if(res != 0)
            {
                NSLog(@"Flash detect init failed");
                dispatch_sync(dispatch_get_main_queue(), ^{
                    NSString* tips = @"未检测到人脸";
                    [self showLiveneeTips:tips];
                });
                
                break;
            }
            NSLog(@"Flash detect init");
            self.screenFlashStat.hasInit = true;
            break;
        }
    } while (0);
    
    //提示交互式动作
    do {
        __block NSString* tips = @"";
            switch (action)
            {
                case ASF_ACTION_TYPE_EB:
                    tips = @"请眨眼";
                    break;
                case ASF_ACTION_TYPE_MO:
                    tips = @"请张嘴";
                    break;
                case ASF_ACTION_TYPE_HL:
                    tips = @"请右摇头";
                    break;
                case ASF_ACTION_TYPE_HR:
                    tips = @"请左摇头";
                    break;
                default:
                    break;
            }
            
            NSInteger res = [self.videoProcessor actionDetect:cameraDataAction action:action isReset:0];
            if(res != 0)
            {
                tips = @"未检测到人脸";

            }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self showLiveneeTips:tips];
        });
        
        break;
    
    } while (0);
    [Utility freeCameraData:cameraDataAction];
}
#pragma mark - AVCaptureOutputDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput
 didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection
{
   
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (!pixelBuffer) return;
    
   
    do {
        if(self.screenFlashStat.isFlashIng)
        {
            [self screenFlashCaptureDeal:sampleBuffer];

        }
        else if(self.screenFlashStat.isActionDetectIng)
        {
                
            [self actionCaptureDeal:sampleBuffer];
         
        }
    } while (0);
    


    //NSLog(@"video: %d %d", CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        // 更新 MetalView 图像（支持镜像）
        [self.metalView updatePixelBuffer:pixelBuffer mirror:NO];
    });
    
    
}





#pragma mark - ASFVideoFlashLivenessDelegate

- (void)showLiveneeTips:(NSString*)tips{
   // self.labelName.text = [NSString stringWithFormat:@"比对结果：%@", personName];
    
    // 取消旧定时器
    if (self.tipsShowTimer)
    {
        [self.tipsShowTimer invalidate];
        self.tipsShowTimer = nil;

    }
   
    // 更新UI
    self.titleLabel.text = [NSString stringWithFormat:@"%@", tips];

    // 创建新定时器
    self.tipsShowTimer = [NSTimer scheduledTimerWithTimeInterval:3
                                                      repeats:NO
                                                        block:^(NSTimer * _Nonnull timer) {
        self.titleLabel.text  = @"";
    }];
}


-(void) updateLivenessResult:(NSInteger)ret
                 livenessRes:(NSInteger)livenessRes
{
    if(MOK == ret && 1 == livenessRes)
    {
        self.screenFlashStat.actionIndex++;
        //动作都完成了
        if(2 == self.screenFlashStat.actionIndex)
        {
            NSLog(@"Finish action");
            [self clearScreenFlashStat];
            self.titleLabel.text  = @"活体检测结果: 活体";
            if (self.actionDetectTimer)
            {
                [self.actionDetectTimer invalidate];
                self.actionDetectTimer = nil;

            }
            self.actionLivenessCheck.enabled =YES;
            self.actionLivenessCheck.alpha = 1.0;
            self.flashLivenessCheck.enabled =YES;
            self.flashLivenessCheck.alpha = 1.0;
        }
        else
        {
            //下一个动作,重置定时器
            [self singleActionTimeOutDeal];
        }
    }
   
}
@end

NS_ASSUME_NONNULL_END
