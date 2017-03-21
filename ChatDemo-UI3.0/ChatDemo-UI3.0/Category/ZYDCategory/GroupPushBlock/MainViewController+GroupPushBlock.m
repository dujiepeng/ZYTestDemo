//
//  MainViewController+GroupPushBlock.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/3/17.
//  Copyright © 2017年 WYZ. All rights reserved.
//

#import "MainViewController+GroupPushBlock.h"
#import <objc/runtime.h>


@implementation MainViewController (GroupPushBlock)

+ (void)load {
    Method oldUnreadMethod = class_getInstanceMethod([MainViewController class], @selector(setupUnreadMessageCount));
    Method newUnreadMethod = class_getInstanceMethod([MainViewController class], @selector(GPBSetupUnreadMessageCount));
    method_exchangeImplementations(oldUnreadMethod, newUnreadMethod);
}

- (void)GPBSetupUnreadMessageCount {
    // 统计未读消息数
    NSArray *conversations = [[EMClient sharedClient].chatManager getAllConversations];
    NSArray *pushGroupIds = [[EMClient sharedClient].groupManager getGroupsWithoutPushNotification:nil];
    NSInteger unreadCount = 0;
    for (EMConversation *conversation in conversations) {
        if (![pushGroupIds containsObject:conversation.conversationId]) {
            unreadCount += conversation.unreadMessagesCount;
        }
    }
    if (self.tabBar.items.count > 0) {
        if (unreadCount > 0) {
            [(UITabBarItem *)self.tabBar.items[0] setBadgeValue:[NSString stringWithFormat:@"%i",(int)unreadCount]];
        }else{
            [(UITabBarItem *)self.tabBar.items[0] setBadgeValue:nil];
        }
    }
    UIApplication *application = [UIApplication sharedApplication];
    [application setApplicationIconBadgeNumber:unreadCount];
}

@end
