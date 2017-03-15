//
//  ShareFileActivity.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 15/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "ShareFileActivity.h"
NSString *const shareFileActivity = @"ShareFileActivity";

@implementation ShareFileActivity
- (NSString *)activityType
{
    return shareFileActivity;
}

- (NSString *)activityTitle
{
    return @"打开方式";
}

- (UIImage *)activityImage
{
    return nil;
}

+ (UIActivityCategory)activityCategory
{
    return UIActivityCategoryShare;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    NSLog(@"activityItems = %@", activityItems);
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    NSLog(@"Activity prepare");
}

- (void)performActivity
{
    NSLog(@"Activity run");
}

- (void)activityDidFinish:(BOOL)completed
{
    NSLog(@"Activity finish");
}

@end
