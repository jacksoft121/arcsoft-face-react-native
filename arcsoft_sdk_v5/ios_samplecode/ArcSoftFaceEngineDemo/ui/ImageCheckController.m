//
//  ImageCheckController.m
//  ArcSoftFaceEngineDemo
//
//  Created by noit on 2018/9/5.
//  Copyright © 2018年 ArcSoft. All rights reserved.
//

#import "ImageCheckController.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>
#import "ColorFormatUtil.h"
#import "Utility.h"
#import "ImageChooseControl.h"
#import "SelfBtnStyleUtil.h"


#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define MAX_FACE 50

@interface ImageCheckController () <ImageChooseControlDelegate> {
    ArcSoftFaceEngine *engine;
    UIImageView *_resualtImgView;
    UIImageView *_refImgView1;
    UIImage *selectImage;
    UIImage *selectImage1;
    UIButton *btStartCheck;
    UILabel *tvCheckTip;
    UIScrollView *scrollView;
    UILabel* labelFD;
    UILabel* labelAge;
    UILabel *labelGender;
    UILabel *labelAngle;
    UILabel *labelFR1;
    UILabel *labelFM;
}
@end

@implementation ImageCheckController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    engine = [[ArcSoftFaceEngine alloc] init];
    MRESULT mr = [engine initFaceEngineWithDetectMode:ASF_DETECT_MODE_IMAGE
                                  orientPriority:ASF_OP_ALL_OUT
                                      maxFaceNum:10
                                    combinedMask:ASF_FACE_DETECT | ASF_FACERECOGNITION | ASF_AGE | ASF_GENDER];
    NSLog(@"初始化结果为：%ld", mr);
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight * 2)];
    scrollView.scrollEnabled = YES;
    scrollView.showsVerticalScrollIndicator = YES;
    [self.view addSubview:scrollView];
    
    UIButton* btCancel = [[UIButton alloc] initWithFrame:CGRectMake(20, 40, 100, 44)];
    //[btCancel setTitle:@"返回" forState:UIControlStateNormal];
    [btCancel setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [btCancel addTarget:self action:@selector(cancel:)
       forControlEvents:UIControlEventTouchUpInside];
    [SelfBtnStyleUtil setupDefaultButtonStyle:btCancel title:@"返回" ];
    [scrollView addSubview:btCancel];
//    
//    // 设置约束：左上角，距离屏幕边缘 20pt
//    [NSLayoutConstraint activateConstraints:@[
//        
//        [btCancel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:40],
//        [btCancel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor  constant:40],
//        [btCancel.widthAnchor constraintEqualToConstant:100],
//        [btCancel.heightAnchor constraintEqualToConstant:44]
//    ]];
    
    UILabel* tvImage1 = [[UILabel alloc] initWithFrame:CGRectMake(60, 90, 150, 20)];
    tvImage1.text = @"图1：";
    tvImage1.textColor = [UIColor blackColor];
    [scrollView addSubview:tvImage1];
    
    _refImgView1 = [[UIImageView alloc] initWithFrame:CGRectMake(60, 120, 160, 160)];
    UIImage* imgSrc1 = [UIImage imageNamed:@"1"];
    [_refImgView1 setImage:imgSrc1];
    [scrollView addSubview:_refImgView1];
    selectImage1 = imgSrc1;
    
    ImageChooseControl * imgChooseControl1 = [ImageChooseControl alloc];
    imgChooseControl1.pickerTitle         = @"选择图片1";
    imgChooseControl1.superViewController = self;
    imgChooseControl1.delegate            = self;
    imgChooseControl1.identify            = @"button1";
    [imgChooseControl1 initWithFrame:CGRectMake(100, 290, 120, 40)];
    [scrollView addSubview:imgChooseControl1];
    
    _resualtImgView = [[UIImageView alloc] initWithFrame:CGRectMake(60, 340, 160, 160)];
    _resualtImgView.backgroundColor = [UIColor lightGrayColor];
    [scrollView addSubview:_resualtImgView];
    
    ImageChooseControl * imgChooseControl2 = [ImageChooseControl alloc];
                                        
    imgChooseControl2.pickerTitle         = @"选择图片2";
    imgChooseControl2.superViewController = self;
    imgChooseControl2.delegate            = self;
    imgChooseControl2.identify            = @"button2";
    [imgChooseControl2 initWithFrame:CGRectMake(100, 510, 120, 40)];
    [scrollView addSubview:imgChooseControl2];
    
    
    btStartCheck = [[UIButton alloc] initWithFrame:CGRectMake(100, 570, 100, 40)];
    [btStartCheck setTitle:@"开始检测" forState:UIControlStateNormal];
    [btStartCheck setTitleColor:[UIColor blueColor]  forState:UIControlStateNormal];
    [btStartCheck setBackgroundColor:[UIColor grayColor]];
    [btStartCheck addTarget:self action:@selector(startCheck:) forControlEvents:UIControlEventTouchUpInside];
    [SelfBtnStyleUtil setupDefaultButtonStyle:btStartCheck title:nil ];
    
    [scrollView addSubview:btStartCheck];
    
    tvCheckTip = [[UILabel alloc] initWithFrame:CGRectMake(5, 620, 300, 50)];
    tvCheckTip.numberOfLines = 2;
    tvCheckTip.text = @"检测结果(以图2为准，若检测到多人脸，下面只输出第一个人脸的数据):";
    [scrollView addSubview:tvCheckTip];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [engine unInitFaceEngine];
}

- (IBAction)cancel:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imageChooseControl:(ImageChooseControl *)control didChooseFinished:(UIImage *)image  identify:(NSString *)identify{
   
    if([identify isEqualToString:@"button1"])
    {
        NSLog(@"button1 select");
        selectImage1 = image;
        [_refImgView1 setImage:image];
    }
    else if([identify isEqualToString:@"button2"])
    {
        NSLog(@"button2 select");
        selectImage = image;
        [_resualtImgView setImage:image];
    }
    
    [self clearChildView];
}

- (void)imageChooseControl:(ImageChooseControl *)control didClearImage:(UIImage *)image identify:(NSString *)identify {
    [self clearChildView];
    if([identify isEqualToString:@"button1"])
    {
        [_refImgView1 setImage:image];
        selectImage1 = nil;
    }
    else if([identify isEqualToString:@"button2"])
    {
        [_resualtImgView setImage:image];
        selectImage = nil;
    }
    
}

- (void)clearChildView {
    [labelFD removeFromSuperview];
    [labelAge removeFromSuperview];
    [labelGender removeFromSuperview];
    [labelAngle removeFromSuperview];
    [labelFR1 removeFromSuperview];
    [labelFM removeFromSuperview];
}

- (IBAction)startCheck:(UIButton *)sender {
    [self clearChildView];
    if(nil == selectImage)
    {
        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"请选择图片" message:@"" preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertController animated:YES completion:nil];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }]];
        return;
    }
    //对图片宽高进行对齐处理
    int imageWidth = selectImage.size.width;
    int imageHeight = selectImage.size.width;
    if (imageWidth % 4 != 0) {
        imageWidth = imageWidth - (imageWidth % 4);
    }
    if (imageHeight % 2 != 0) {
        imageHeight = imageHeight - (imageHeight % 2);
    }
    CGRect rect = CGRectMake(0, 0, imageWidth, imageHeight);
    selectImage = [Utility clipWithImageRect:rect clipImage:selectImage];
    
    unsigned char* pRGBA = [ColorFormatUtil bitmapFromImage:selectImage];
    MInt32 dataWidth = selectImage.size.width;
    MInt32 dataHeight = selectImage.size.height;
    MUInt32 format = ASVL_PAF_NV12;
    MInt32 pitch0 = dataWidth;
    MInt32 pitch1 = dataWidth;
    MUInt8* plane0 = (MUInt8*)malloc(dataHeight * dataWidth * 3/2);
    MUInt8* plane1 = plane0 + dataWidth * dataHeight;
    unsigned char* pBGR = (unsigned char*)malloc(dataHeight * LINE_BYTES(dataWidth, 24));
    RGBA8888ToBGR(pRGBA, dataWidth, dataHeight, dataWidth * 4, pBGR);
    SafeArrayFree(pRGBA);
    BGRToNV12(pBGR, dataWidth, dataHeight, plane0, pitch0, plane1, pitch1);
    SafeArrayFree(pBGR);

    ASF_MultiFaceInfo fdResult = {0};
//    MRECT faceRects[MAX_FACE] = {0};
//    MInt32 faceOrients[MAX_FACE] = {0};
//    fdResult.faceRect = faceRects;
//    fdResult.faceOrient = faceOrients;
    
    //FD
    MRESULT mr = [engine detectFacesWithWidth:dataWidth
                                       height:dataHeight
                                         data:plane0
                                       format:format
                                      faceRes:&fdResult];
    
    CGRect tvCheckTipFrame = tvCheckTip.frame;
    CGFloat checkTipY = (int)tvCheckTipFrame.origin.y;
    labelFD = [[UILabel alloc] init];
    [labelFD setFrame:CGRectMake(5, checkTipY + 40, 300, 55)];
    [labelFD setNumberOfLines:2];
    NSString* fdResultStr = @"";
    if (mr == MOK) {
        if (fdResult.faceNum == 0) {
            fdResultStr = @"图2未检测到人脸";
        } else {
            fdResultStr = [NSString stringWithFormat:@"detectFaces检测成功,人脸框：rect[%d,%d,%d,%d]",
                           fdResult.faceRect[0].left, fdResult.faceRect[0].top,
                           fdResult.faceRect[0].right, fdResult.faceRect[0].bottom];
        }
    } else {
        fdResultStr = [NSString stringWithFormat:@"图2 detectFaces检测失败：%ld，请重新选择", mr];
    }
    [labelFD setText:fdResultStr];
    [labelFD setTextColor:[UIColor redColor]];
    
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGSize targetSize = CGSizeMake(selectImage.size.width, selectImage.size.height);
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, targetSize.width, targetSize.height,
                                                       8, targetSize.width * 4, rgb,
                                                       kCGImageAlphaPremultipliedFirst);
    CGRect imageRect;
    imageRect.origin = CGPointMake(0, 0);
    imageRect.size = targetSize;
    CGContextDrawImage(bitmapContext, imageRect, selectImage.CGImage);
    for (int i = 0; i < fdResult.faceNum; i ++) {
        MRECT rect = fdResult.faceRect[i];
        CGRect cgRect = CGRectMake(rect.left, targetSize.height - rect.bottom, rect.right - rect.left, rect.bottom - rect.top);
        CGContextAddRect(bitmapContext, cgRect);
    }
    CGContextSetRGBStrokeColor(bitmapContext, 255, 0, 0, 1);
    CGContextSetLineWidth(bitmapContext, 4.0);
    CGContextStrokePath(bitmapContext);
    CGImageRef imageRef = CGBitmapContextCreateImage(bitmapContext);
    UIImage * image = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGContextRelease(bitmapContext);
    CGColorSpaceRelease(rgb);
    [_resualtImgView setImage:image];
    
    [scrollView addSubview:labelFD];
    
    if (mr == MOK) {
        NSTimeInterval begin = [[NSDate date] timeIntervalSince1970];
        mr = [engine processWithWidth:dataWidth
                               height:dataHeight
                                 data:plane0
                               format:format
                              faceRes:&fdResult
                                 mask:ASF_AGE | ASF_GENDER];
        NSTimeInterval cost = [[NSDate date] timeIntervalSince1970] - begin;
        NSLog(@"processTime=%d", (int)(cost * 1000));
        NSLog(@"process:%ld", mr);
        if (mr == MOK) {
            //age
            ASF_AgeInfo ageInfo = {0};
            mr = [engine getAge:&ageInfo];
            if (mr == MOK) {
                NSLog(@"age:%d", (int)ageInfo.ageArray[0]);
                labelAge = [[UILabel alloc] init];
                [labelAge setFrame:CGRectMake(5, checkTipY + 80, 200, 45)];
                NSString *strFD = [NSString stringWithFormat:@"年龄为：%d", (int)ageInfo.ageArray[0]];
                [labelAge setText:strFD];
                [labelAge setTextColor:[UIColor redColor]];
                [scrollView addSubview:labelAge];
            }
            
            //gender
            ASF_GenderInfo genderInfo = {0};
            mr = [engine getGender:&genderInfo];
            if (mr == MOK) {
                labelGender = [[UILabel alloc] init];
                [labelGender setFrame:CGRectMake(5, checkTipY + 105, 200, 45)];
                NSString *strGender = [NSString stringWithFormat:@"性别为：%@", genderInfo.genderArray[0] == 1 ? @"女" : @"男"];
                [labelGender setText:strGender];
                [labelGender setTextColor:[UIColor redColor]];
                [scrollView addSubview:labelGender];
            }
            
            //3DAngle
            if (mr == MOK) {
                labelAngle = [[UILabel alloc] init];
                [labelAngle setNumberOfLines:3];
                [labelAngle setFrame:CGRectMake(5, checkTipY + 130, 300, 95)];
                NSString *strAngle = [NSString stringWithFormat:@"3DAngle:[yaw:%f,roll:%f,pitch:%f]", fdResult.face3DAngleInfo.yaw[0], fdResult.face3DAngleInfo.roll[0], fdResult.face3DAngleInfo.pitch[0]];
                [labelAngle setText:strAngle];
                [labelAngle setTextColor:[UIColor redColor]];
                [scrollView addSubview:labelAngle];
            }
            
            //FR
            ASF_SingleFaceInfo frInputFace = {0};
            frInputFace.faceRect.left = fdResult.faceRect[0].left;
            frInputFace.faceRect.top = fdResult.faceRect[0].top;
            frInputFace.faceRect.right = fdResult.faceRect[0].right;
            frInputFace.faceRect.bottom = fdResult.faceRect[0].bottom;
            frInputFace.faceOrient = fdResult.faceOrient[0];
            frInputFace.faceDataInfo.data = fdResult.faceDataInfoList[0].data;
            frInputFace.faceDataInfo.dataSize = fdResult.faceDataInfoList[0].dataSize;
            
            ASF_FaceFeature feature1 = {0};
            ASF_FaceFeature featureCopy = {0};
            NSTimeInterval begin = [[NSDate date] timeIntervalSince1970];
            mr = [engine extractFaceFeatureWithWidth:dataWidth
                                              height:dataHeight
                                                data:plane0
                                              format:format
                                            faceInfo:&frInputFace
                                             feature:&feature1];
            NSTimeInterval cost = [[NSDate date] timeIntervalSince1970] - begin;
            if (mr == MOK) {
                NSLog(@"FRTime:%dms, feature1:%d", (int)(cost * 1000), feature1.featureSize);
                //复制特征值
                featureCopy.featureSize = feature1.featureSize;
                featureCopy.feature = (MByte*)malloc(featureCopy.featureSize);
                memcpy(featureCopy.feature,feature1.feature,feature1.featureSize);
                
                labelFR1 = [[UILabel alloc] init];
                [labelFR1 setNumberOfLines:1];
                [labelFR1 setFrame:CGRectMake(5, checkTipY + 205, 320, 45)];
                NSString *strFR1 = [NSString stringWithFormat:@"人脸特征长度为:%d", feature1.featureSize];
                [labelFR1 setText:strFR1];
                [labelFR1 setTextColor:[UIColor redColor]];
                [scrollView addSubview:labelFR1];
            }
            
            int imageWidth = selectImage1.size.width;
            int imageHeight = selectImage1.size.width;
            if (imageWidth % 4 != 0) {
                imageWidth = imageWidth - (imageWidth % 4);
            }
            if (imageHeight % 2 != 0) {
                imageHeight = imageHeight - (imageHeight % 2);
            }
            CGRect rect = CGRectMake(0, 0, imageWidth, imageHeight);
            selectImage1 = [Utility clipWithImageRect:rect clipImage:selectImage1];

            unsigned char* pRGBA2 = [ColorFormatUtil bitmapFromImage:selectImage1];
            MInt32 picWidth2 = selectImage1.size.width;
            MInt32 picHeight2 = selectImage1.size.height;
            NSLog(@"width2:%d height2:%d", picWidth2, picHeight2);
            MInt32 format2 = ASVL_PAF_NV12;
            MInt32 pi32Pitch20 = picWidth2;
            MInt32 pi32Pitch21 = picWidth2;
            MUInt8* ppu8Plane20 = (MUInt8*)malloc(picHeight2 * picWidth2 * 3/2);
            MUInt8* ppu8Plane21 = ppu8Plane20 + pi32Pitch20 * picHeight2;
            unsigned char* pBGR2 = (unsigned char*)malloc(picHeight2 * LINE_BYTES(picWidth2, 24));
            RGBA8888ToBGR(pRGBA2, picWidth2, picHeight2, picWidth2 * 4, pBGR2);
            SafeArrayFree(pRGBA2);
            BGRToNV12(pBGR2, picWidth2, picHeight2, ppu8Plane20, pi32Pitch20, ppu8Plane21, pi32Pitch21);
            SafeArrayFree(pBGR2);

            ASF_MultiFaceInfo fdResult2 = {0};
            
            do {
                mr = [engine detectFacesWithWidth:picWidth2
                                           height:picHeight2
                                             data:ppu8Plane20
                                           format:format2
                                          faceRes:&fdResult2];
                
                if (mr == MOK)
                {
                    if (fdResult2.faceNum == 0)
                    {
                        fdResultStr = @"图1未检测到人脸";
                        [labelFD setText:fdResultStr];
                        [labelFD setTextColor:[UIColor redColor]];
                        break;
                    }
                }
                else
                {
                    fdResultStr = [NSString stringWithFormat:@"图1 detectFaces检测失败：%ld，请重新选择", mr];
                    [labelFD setText:fdResultStr];
                    [labelFD setTextColor:[UIColor redColor]];
                    break;
                }
                if (mr == MOK)
                {
                    ASF_SingleFaceInfo frInputFace2 = {0};
                    frInputFace2.faceRect.left = fdResult2.faceRect[0].left;
                    frInputFace2.faceRect.top = fdResult2.faceRect[0].top;
                    frInputFace2.faceRect.right = fdResult2.faceRect[0].right;
                    frInputFace2.faceRect.bottom = fdResult2.faceRect[0].bottom;
                    frInputFace2.faceOrient = fdResult2.faceOrient[0];
                    frInputFace2.faceDataInfo.data = fdResult2.faceDataInfoList[0].data;
                    frInputFace2.faceDataInfo.dataSize = fdResult2.faceDataInfoList[0].dataSize;
                    
                    ASF_FaceFeature feature2 = {0};
                    mr = [engine extractFaceFeatureWithWidth:picWidth2
                                                      height:picHeight2
                                                        data:ppu8Plane20
                                                      format:format2
                                                    faceInfo:&frInputFace2
                                                     feature:&feature2];
                    
                    
                    //FM
                    MFloat confidence = 0;
                    mr = [engine compareFaceWithFeature:&featureCopy
                                               feature2:&feature2
                                                 confidenceLevel:&confidence];
                    
                    if (mr == MOK) {
                        NSLog(@"FM比对结果为：%f", confidence);
                        labelFM = [[UILabel alloc] init];
                        [labelFM setNumberOfLines:1];
                        [labelFM setFrame:CGRectMake(5, checkTipY + 255, 320, 45)];
                        NSString *strFM = [NSString stringWithFormat:@"图1和图2比对结果：%f", confidence];
                        [labelFM setText:strFM];
                        [labelFM setTextColor:[UIColor redColor]];
                        [scrollView addSubview:labelFM];
                        
                        scrollView.contentSize = CGSizeMake(kScreenWidth + 50, kScreenHeight * 2.5);
                    } else {
                        NSLog(@"FM失败为：%ld", mr);
                    }
                }
                
            } while (0);
            if(ppu8Plane20 != NULL)
            {
                SafeArrayFree(ppu8Plane20);
            }
            
            if (featureCopy.feature != NULL)
            {
                SafeArrayFree(featureCopy.feature);
            }
           
           
        }
    }
    SafeArrayFree(plane0);
}

@end
