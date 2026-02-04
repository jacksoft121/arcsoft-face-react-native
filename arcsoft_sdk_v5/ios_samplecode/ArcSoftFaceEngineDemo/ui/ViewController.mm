//
//  ViewController.m
//

#import "ViewController.h"
#import "ImageCheckController.h"
#import "VideoCheckController.h"
#import "ScreenFlashCheckController.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>
#import "DateUtils.h"
#import "SelfBtnStyleUtil.h"
@interface ViewController()
@end


@interface StatusResult : NSObject
@property (nonatomic, assign) NSInteger status;
@property (nonatomic, strong, nullable) NSString *errorMessage;
@end

@implementation StatusResult
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *buttonE = [UIButton buttonWithType:UIButtonTypeCustom];
    [buttonE setFrame:CGRectMake(50, 120, 200, 100)];
    [buttonE setBackgroundColor:[UIColor clearColor]];
    [buttonE setTitle:@"引擎激活" forState:UIControlStateNormal];
    [buttonE addTarget:self action:@selector(engineActive:) forControlEvents:UIControlEventTouchUpInside];
    [SelfBtnStyleUtil setupDefaultButtonStyle:buttonE title:nil];
    [self.view addSubview:buttonE];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(50, 240, 200, 100)];
    [button setBackgroundColor:[UIColor clearColor]];
    [button setTitle:@"Image模式检测" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(imageCheck:) forControlEvents:UIControlEventTouchUpInside];
    [SelfBtnStyleUtil setupDefaultButtonStyle:button title:nil];
    [self.view addSubview:button];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button2 setFrame:CGRectMake(50, 360, 200, 100)];
    [button2 setBackgroundColor:[UIColor clearColor]];
    [button2 setTitle:@"Video模式检测" forState:UIControlStateNormal];
    [button2 addTarget:self action:@selector(videoCheck:) forControlEvents:UIControlEventTouchUpInside];
    [SelfBtnStyleUtil setupDefaultButtonStyle:button2 title:nil];
    [self.view addSubview:button2];
    
    UIButton *btScreenFlash = [UIButton buttonWithType:UIButtonTypeCustom];
    [btScreenFlash setFrame:CGRectMake(50, 480, 200, 100)];
    [btScreenFlash setBackgroundColor:[UIColor clearColor]];
    [btScreenFlash setTitle:@"交互式炫光活体检测" forState:UIControlStateNormal];
    [btScreenFlash addTarget:self action:@selector(screenFlashCheck:) forControlEvents:UIControlEventTouchUpInside];
    [SelfBtnStyleUtil setupDefaultButtonStyle:btScreenFlash title:nil];
    [self.view addSubview:btScreenFlash];
}

-(void)engineActive:(UIButton*)sender {
    NSString *appid = @"";
    NSString *sdkkey = @"";
    ArcSoftFaceEngine *engine = [[ArcSoftFaceEngine alloc] init];
    MRESULT mr = [engine activeWithAppId:appid SDKKey:sdkkey];
    if (mr == MOK) {
        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"SDK激活成功" message:@"" preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertController animated:YES completion:nil];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }]];
    } else if(mr == MERR_ASF_ALREADY_ACTIVATED){
        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"SDK已激活" message:@"" preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertController animated:YES completion:nil];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }]];
    } else {
        NSString *result = [NSString stringWithFormat:@"SDK激活失败：%ld", mr];
        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:result message:@"" preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertController animated:YES completion:nil];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }]];
    }
}
-(void)showActiveResult:(NSString*)messageInfo
{
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:messageInfo message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alertController animated:YES completion:nil];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
}
-(StatusResult*)getActiveStatus
{
    StatusResult *result = [StatusResult alloc];
    result.status = 0;
    result.errorMessage = @"";
    ArcSoftFaceEngine *engine = [[ArcSoftFaceEngine alloc] init];
    ArcSoftActiveInfo *activeFileInfo = [ArcSoftActiveInfo alloc];
    MRESULT mr = [engine getActiveFileInfo:activeFileInfo];
    result.status = (int)mr;
    if(mr != MOK)
    {
        result.errorMessage = @"获取激活文件信息失败";
    }
    else
    {
        NSDate *startDate = [DateUtils dateFromShortStyleString:activeFileInfo.startTime];
        NSDate *endDate = [DateUtils dateFromShortStyleString:activeFileInfo.endTime];
        // 和当前时间比较
        NSDate *now = [NSDate date];
        if ([endDate compare:now] == NSOrderedDescending || [endDate compare:now] == NSOrderedSame)
        {
            result.status  = 0;
        }
        else
        {
            result.status = - 1;
            result.errorMessage = @"激活过期";
        }

    }
    return result;
}
-(void)imageCheck:(UIButton*)sender {
    StatusResult *result = [StatusResult alloc];
    result = [self getActiveStatus];
    if(result.status != 0)
    {
        [self showActiveResult:result.errorMessage];
    }
    else
    {
        ImageCheckController *imageC = [[ImageCheckController alloc] init];
        imageC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:imageC animated:true completion:nil];
    }
   
}

-(void)videoCheck:(UIButton*)sender {
    StatusResult *result = [StatusResult alloc];
    result = [self getActiveStatus];
    if(result.status != 0)
    {
        [self showActiveResult:result.errorMessage];
    }
    else
    {
        VideoCheckController *videoC = [[VideoCheckController alloc] init];
        videoC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:videoC animated:true completion:nil];
    }
   
}

-(void)screenFlashCheck:(UIButton*)sender {
    StatusResult *result = [StatusResult alloc];
    result = [self getActiveStatus];
    if(result.status != 0)
    {
        [self showActiveResult:result.errorMessage];
    }
    else
    {
        ScreenFlashCheckController *videoFlashC = [[ScreenFlashCheckController alloc] init];
        videoFlashC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:videoFlashC animated:true completion:nil];
    }
   
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
