//
//  SelfBtnStyleUtil.m
//  ArcSoftFaceEngineDemo
//
//  Created by arc-mac-m4 on 2025/11/10.
//  Copyright © 2025 ArcSoft. All rights reserved.
//

#import "SelfBtnStyleUtil.h"
#import "UIKit/UILabel.h"
NS_ASSUME_NONNULL_BEGIN

@implementation SelfBtnStyleUtil

+ (void)setupDefaultButtonStyle:(UIButton *)button title:(NSString *)title {
    if(title)
    {
        [button setTitle:title forState:UIControlStateNormal];
    }
    
    
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
@end

NS_ASSUME_NONNULL_END
