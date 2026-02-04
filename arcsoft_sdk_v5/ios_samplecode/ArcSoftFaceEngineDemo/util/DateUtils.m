//
//  DateUtils.m
//  ArcSoftFaceEngineDemo
//
//  Created by arc-mac-m4 on 2025/11/11.
//  Copyright © 2025 ArcSoft. All rights reserved.
//

#import "DateUtils.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DateUtils



+ (NSDate *)dateFromShortStyleString:(NSString *)dateString {
    if (!dateString || dateString.length == 0) return nil;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterShortStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    formatter.locale = [NSLocale currentLocale]; // 保持与生成字符串一致
    
    NSDate *date = [formatter dateFromString:dateString];
    if (!date) {
        NSLog(@"解析失败，检查字符串格式: %@", dateString);
    }
    return date;
}

+ (NSTimeInterval)timestampFromShortStyleString:(NSString *)dateString {
    NSDate *date = [self dateFromShortStyleString:dateString];
    if (!date) return 0;
    return [date timeIntervalSince1970];
}

@end

NS_ASSUME_NONNULL_END
