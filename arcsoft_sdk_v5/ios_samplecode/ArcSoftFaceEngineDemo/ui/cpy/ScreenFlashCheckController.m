//
//  ScreenFlashCheckController.m
//  ArcSoftFaceEngineDemo
//
//  Created by arc-mac-m4 on 2025/10/30.
//  Copyright © 2025 ArcSoft. All rights reserved.
//

#import "ScreenFlashCheckController.h"
#import "ASFCameraController.h"
#import "CircularMetalView.h"
#import "ASFVideoProcessor.h"
#import "Utility.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>

NS_ASSUME_NONNULL_BEGIN

#define IMAGE_WIDTH 720
#define IMAGE_HEIGHT 1280

@interface ScreenFlashCheckController()<ASFCameraControllerDelegate, ASFVideoProcessorDelegate>

@property (nonatomic, strong) ASFCameraController *cameraController;
@property (nonatomic, strong) ASFVideoProcessor *videoProcessor;
@property (nonatomic, strong) NSMutableArray *arrayAllFaceRectView;
@property (weak, nonatomic) IBOutlet UIButton *actionLivenessCheck;
@property (weak, nonatomic) IBOutlet UIButton *flashLivenessCheck;
@property (weak, nonatomic) IBOutlet CircularMetalView  *metalView;


@end

@implementation ScreenFlashCheckController


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
    // 设置圆形外观
       CGFloat diameter = [UIScreen mainScreen].bounds.size.width / 2.0;
       self.metalView.layer.cornerRadius = diameter / 2.0;
       self.metalView.layer.masksToBounds = YES;
       self.metalView.layer.borderColor = [UIColor whiteColor].CGColor;
       self.metalView.layer.borderWidth = 6.0;

       // 设置 Metal 渲染的设备
       if (!self.metalView.device) {
           self.metalView.device = MTLCreateSystemDefaultDevice();
       }

       NSLog(@"✅ MetalView 初始化完成: %@", self.metalView.device);
    
    self.metalView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *w = [self.metalView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.5];
    NSLayoutConstraint *h = [self.metalView.heightAnchor constraintEqualToAnchor:self.metalView.widthAnchor multiplier:1.0];
    NSLayoutConstraint *cx = [self.metalView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor];
    NSLayoutConstraint *cy = [self.metalView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:0]; // 可改偏移
    [NSLayoutConstraint activateConstraints:@[w,h,cx,cy]];
    
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
    // 让 metalView 保持严格的正方形
      CGFloat side = MIN(self.metalView.bounds.size.width, self.metalView.bounds.size.height);
      CGRect frame = self.metalView.frame;
      frame.size.width = frame.size.height = side;
      self.metalView.frame = frame;

      // 或者更推荐：加 AutoLayout 约束来强制正方形
      [self.metalView.widthAnchor constraintEqualToAnchor:self.metalView.heightAnchor].active = YES;

      // 让它的 layer 裁剪成圆形
      self.metalView.layer.cornerRadius = side / 2.0;
      self.metalView.layer.masksToBounds = YES;
    
}


#pragma mark - AVCaptureOutputDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput
 didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection
{
    ASF_CAMERA_DATA* cameraData = [Utility getCameraDataFromSampleBuffer:sampleBuffer];
    NSArray *arrayFaceInfo = [self.videoProcessor process:cameraData];
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (!pixelBuffer) return;

    CGSize videoSize = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer),
                                     CVPixelBufferGetHeight(pixelBuffer));
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.metalView.videoSize = videoSize;
        self.metalView.pixelBuffer = pixelBuffer;
    });
    
    [Utility freeCameraData:cameraData];
}





#pragma mark - ASFVideoProcessorDelegate

- (void)processRecognized:(NSString *)personName {
   // self.labelName.text = [NSString stringWithFormat:@"比对结果：%@", personName];
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

NS_ASSUME_NONNULL_END
