//
//  VideoCheckController.m
//  ArcSoftFaceEngineDemo
//
//  Created by noit on 2018/9/5.
//  Copyright © 2018年 ArcSoft. All rights reserved.
//

#import "VideoCheckController.h"
#import "ASFCameraController.h"
#import "MetalView.h"
#import "ASFVideoProcessor.h"
#import "Utility.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>

#define IMAGE_WIDTH 720
#define IMAGE_HEIGHT 1280

@interface VideoCheckController ()<ASFCameraControllerDelegate, ASFVideoProcessorDelegate>
@property (nonatomic, strong) ASFCameraController *cameraController;
@property (nonatomic, strong) ASFVideoProcessor *videoProcessor;
@property (nonatomic, strong) NSMutableArray *arrayAllFaceRectView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (weak, nonatomic) IBOutlet MetalView *metalView;

@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UIButton *buttonRegister;
@end

@implementation VideoCheckController


- (void)setupButtonStyle:(UIButton *)button title:(NSString *)title {
    [button setTitle:title forState:UIControlStateNormal];
    
    // 填充背景
    button.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    
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
    
    // ===== 文字自适应宽度 & 换行 =====
    button.titleLabel.adjustsFontSizeToFitWidth = YES;   // 根据按钮宽度自动缩小字体
    button.titleLabel.minimumScaleFactor = 0.5;         // 最小缩小到 50%
    button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail; // 超长显示省略号
    button.titleLabel.numberOfLines = 1;                // 单行显示，可改为 0 支持多行
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.arrayAllFaceRectView = [NSMutableArray arrayWithCapacity:0];
    
    self.videoProcessor = [[ASFVideoProcessor alloc] init];
    self.videoProcessor.delegate = self;
    [self.videoProcessor initProcessor];
    
    self.cameraController = [[ASFCameraController alloc] init];
    self.cameraController.delegate = self;
    UIInterfaceOrientation uiOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self.cameraController setupCaptureSession:(AVCaptureVideoOrientation)uiOrientation];
    
    // Storyboard 拖入 MetalView，initWithCoder 已自动初始化 device & delegate
    self.metalView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view sendSubviewToBack:self.metalView];
    self.metalView.userInteractionEnabled = NO;
    [self.view bringSubviewToFront:self.buttonRegister];
    
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

    [self setupButtonStyle:self.buttonRegister title:@"开始注册人脸"];
    [self setupButtonStyle:self.backButton title:@"返回"];
    self.buttonRegister.translatesAutoresizingMaskIntoConstraints = NO;
    self.backButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.labelName.translatesAutoresizingMaskIntoConstraints = NO;
    // 设置约束：右上角，距离屏幕边缘 20pt
    [NSLayoutConstraint activateConstraints:@[
        [self.buttonRegister.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [self.buttonRegister.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.buttonRegister.widthAnchor constraintEqualToConstant:100],
        [self.buttonRegister.heightAnchor constraintEqualToConstant:44],
        
        [self.backButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [self.backButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor  constant:20],
        [self.backButton.widthAnchor constraintEqualToConstant:100],
        [self.backButton.heightAnchor constraintEqualToConstant:44],
        
        [self.labelName.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:100],
        [self.labelName.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor]
    ]];
}
    

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.cameraController startCaptureSession];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.cameraController stopCaptureSession];
}

- (IBAction)cancel:(id)sender {
    [self.cameraController stopCaptureSession];
    self.cameraController = nil;
    [self.videoProcessor uninitProcessor];
    self.videoProcessor = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // 让 MetalView 全屏
    self.metalView.frame = self.view.bounds;
    
    // MetalView 不拦截触摸事件，按钮可点击
    self.metalView.userInteractionEnabled = NO;
    
    // 1. MetalView 全屏
   self.metalView.frame = self.view.bounds;
   
//   // 2. 视频实际尺寸
//   CGFloat videoWidth = IMAGE_WIDTH;   // 摄像头采集宽度
//   CGFloat videoHeight = IMAGE_HEIGHT;   // 摄像头采集高度
//   
//   CGFloat viewWidth = self.metalView.bounds.size.width;
//   CGFloat viewHeight = self.metalView.bounds.size.height;
//   
//   // 3. 计算 AspectFit 缩放比例
//   CGFloat scaleX = viewWidth / videoWidth;
//   CGFloat scaleY = viewHeight / videoHeight;
//   CGFloat scale = MIN(scaleX, scaleY); // AspectFit 保留黑边
//   
//   // 4. 视频显示区域大小
//   CGFloat videoDisplayWidth = videoWidth * scale;
//   CGFloat videoDisplayHeight = videoHeight * scale;
//   
//   // 5. 视频在 MetalView 中的偏移（黑边）
//   CGFloat offsetX = (viewWidth - videoDisplayWidth) / 2.0;
//   CGFloat offsetY = (viewHeight - videoDisplayHeight) / 2.0;
//   
//   CGRect videoRect = CGRectMake(offsetX, offsetY, videoDisplayWidth, videoDisplayHeight);
//   
//   // 6. 按钮相对于视频区域的位置
//   CGFloat buttonMargin = 10; // 距离视频边缘
//    NSLog(@"x = %f y = %f  width = %f height =%f",  videoRect.origin.x, videoRect.origin.y , self.backButton.frame.size.width, self.backButton.frame.size.height);
//   // 返回按钮：放在视频左上角
//   self.backButton.frame = CGRectMake(
//       videoRect.origin.x + buttonMargin,
//       videoRect.origin.y + buttonMargin,
//       self.backButton.frame.size.width,
//       self.backButton.frame.size.height
//   );
}

- (IBAction)btnRegisterFace:(UIButton *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"注册人脸" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *nameText = alertController.textFields.firstObject;
        NSString *name = nameText.text;
        if (name.length > 0) {
            if ([self.videoProcessor registerDetectedPerson:name]) {
                UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"注册成功" message:@"" preferredStyle:UIAlertControllerStyleAlert];
                [self presentViewController:successAlert animated:YES completion:nil];
                NSTimer *timer = [NSTimer timerWithTimeInterval:5 target:self selector:@selector(timerHideAlertViewController:) userInfo:successAlert repeats:NO];
                [timer fire];
            }
        }
    }];
    [alertController addAction:okAction];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入名称";
    }];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)timerHideAlertViewController:(NSTimer *)timer {
    UIAlertController *alert = (UIAlertController *)timer.userInfo;
    [alert dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AVCaptureOutputDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput
 didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    ASF_CAMERA_DATA* cameraData = [Utility getCameraDataFromSampleBuffer:sampleBuffer];
    NSArray *arrayFaceInfo = [self.videoProcessor process:cameraData];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        // 替换渲染部分：使用 MetalView
        [self.metalView updatePixelBuffer:cameraFrame mirror:NO];
        
        if(self.arrayAllFaceRectView.count >= arrayFaceInfo.count)
        {
            for (NSUInteger face=arrayFaceInfo.count; face<self.arrayAllFaceRectView.count; face++) {
                UIView *faceRectView = [self.arrayAllFaceRectView objectAtIndex:face];
                faceRectView.hidden = YES;
            }
        }
        else
        {
            for (NSUInteger face=self.arrayAllFaceRectView.count; face<arrayFaceInfo.count; face++) {
                UIStoryboard *faceRectStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                UIView *faceRectView = [faceRectStoryboard instantiateViewControllerWithIdentifier:@"FaceRectVideoController"].view;
                [self.view addSubview:faceRectView];
                [self.arrayAllFaceRectView addObject:faceRectView];
            }
        }
        
        for (NSUInteger face = 0; face < arrayFaceInfo.count; face++) {
            UIView *faceRectView = [self.arrayAllFaceRectView objectAtIndex:face];
            NSLog(@"faceRectView width = %f", faceRectView.frame.size.width);
            NSLog(@"faceRectView height = %f", faceRectView.frame.size.height);
            ASFVideoFaceInfo *faceInfo = [arrayFaceInfo objectAtIndex:face];
            faceRectView.hidden = NO;
            faceRectView.frame = [self dataFaceRect2ViewFaceRect:faceInfo.faceRect];
            UILabel* labelInfo = (UILabel*)[faceRectView viewWithTag:1];
            [labelInfo setTextColor:[UIColor yellowColor]];
            labelInfo.font = [UIFont boldSystemFontOfSize:15];
            MInt32 gender = faceInfo.gender;
            NSString *genderInfo = gender == 0 ? @"男" : (gender == 1 ? @"女" : @"不确定");
            NSString *liveness = faceInfo.liveness == 1 ? @"活体" : (faceInfo.liveness == 0) ? @"非活体":@"未知";
            labelInfo.text = [NSString stringWithFormat:@"age:%d gender:%@ live:%@", faceInfo.age, genderInfo, liveness];
            UILabel* labelFaceAngle = (UILabel*)[faceRectView viewWithTag:6];
            labelFaceAngle.font = [UIFont boldSystemFontOfSize:15];
            [labelFaceAngle setTextColor:[UIColor yellowColor]];
            if(faceInfo.face3DAngle.status == 0) {
                labelFaceAngle.text = [NSString stringWithFormat:@"r=%.2f y=%.2f p=%.2f", faceInfo.face3DAngle.rollAngle, faceInfo.face3DAngle.yawAngle, faceInfo.face3DAngle.pitchAngle];
            } else {
                labelFaceAngle.text = @"Failed face 3D Angle";
            }
        }
    });
    
    [Utility freeCameraData:cameraData];
}
#pragma mark - ASFVideoProcessorDelegate

- (void)processRecognized:(NSString *)personName {
    if(personName != nil)
    {
        self.labelName.text = [NSString stringWithFormat:@"比对结果：%@", personName];
    }
    else
    {
        self.labelName.text = [NSString stringWithFormat:@""];
    }
    
}

- (CGRect)dataFaceRect2ViewFaceRect:(MRECT)faceRect {
        CGRect frame = CGRectZero;
        CGRect frameMetalView = self.metalView.frame;
        frame.size.width = CGRectGetWidth(frameMetalView) * (faceRect.right - faceRect.left) / IMAGE_WIDTH;
        frame.size.height = CGRectGetHeight(frameMetalView) * (faceRect.bottom - faceRect.top) / IMAGE_HEIGHT;
        frame.origin.x = CGRectGetWidth(frameMetalView) * faceRect.left / IMAGE_WIDTH;
        frame.origin.y = CGRectGetHeight(frameMetalView) * faceRect.top / IMAGE_HEIGHT;
        return frame;
}
@end
