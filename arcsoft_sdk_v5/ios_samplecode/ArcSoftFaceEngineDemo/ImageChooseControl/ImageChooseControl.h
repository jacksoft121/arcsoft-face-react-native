
#import <UIKit/UIKit.h>

@class ImageChooseControl;

#define SettingCenterUrl @"prefs:root=com.ArtPollo.Artpollo"

@protocol ImageChooseControlDelegate <NSObject>

@optional
- (void)imageChooseControl:(ImageChooseControl *)control didChooseFinished:(UIImage *)image identify:(NSString *)identify;

- (void)imageChooseControl:(ImageChooseControl *)control didClearImage:(UIImage *)image identify:(NSString *)identify;

@end

@interface ImageChooseControl : UIView <UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic,copy) NSString * pickerTitle;

@property (nonatomic,assign) UIViewController * superViewController;

@property (nonatomic,assign) id<ImageChooseControlDelegate> delegate;

@property (nonatomic,strong,readonly) UIImage * image;

@property (nonatomic,copy) NSString * identify;


@end
