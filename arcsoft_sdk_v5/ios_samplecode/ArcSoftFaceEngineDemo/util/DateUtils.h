//
//  DateUtils.h
//  ArcSoftFaceEngineDemo
//
//  Created by arc-mac-m4 on 2025/11/11.
//  Copyright © 2025 ArcSoft. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DateUtils : NSObject
/// 将短日期风格字符串转换为 NSDate
+ (NSDate *)dateFromShortStyleString:(NSString *)dateString;

/// 将短日期风格字符串转换为时间戳
+ (NSTimeInterval)timestampFromShortStyleString:(NSString *)dateString;
@end

NS_ASSUME_NONNULL_END
