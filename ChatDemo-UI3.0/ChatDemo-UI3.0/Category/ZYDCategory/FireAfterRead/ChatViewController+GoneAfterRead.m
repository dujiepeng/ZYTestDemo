//
//  ChatViewController+GoneAfterRead.m
//  ChatDemo-UI3.0
//
//  Created by EaseMob on 2017/3/14.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import "ChatViewController+GoneAfterRead.h"
#import "ChatDemoHelper+GoneAfterRead.h"
#import <objc/runtime.h>
#import "EaseMessageReadManager+GoneAfterRead.h"

@interface ChatViewController()<EaseMessageReadManagerDelegate>

@end

@implementation ChatViewController (GoneAfterRead)


+ (void)load
{
    Method backAction = class_getInstanceMethod([self class], @selector(backAction));
    Method FBackAction = class_getInstanceMethod([RedPacketChatViewController class], @selector(FBackAction));
    method_exchangeImplementations(backAction, FBackAction);
}


@end
