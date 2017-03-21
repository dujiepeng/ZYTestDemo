//
//  EaseConversationCell+GroupPushBlock.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/3/17.
//  Copyright © 2017年 WYZ. All rights reserved.
//

#import "EaseConversationCell+GroupPushBlock.h"
#import <objc/runtime.h>

@implementation EaseConversationCell (GroupPushBlock)

+ (void)load {
    Method oldModelMethod = class_getInstanceMethod([EaseConversationCell class], @selector(setModel:));
    Method newModelMethod = class_getInstanceMethod([EaseConversationCell class], @selector(GPBSetModel:));
    method_exchangeImplementations(oldModelMethod, newModelMethod);
}

- (void)GPBSetModel:(id<IConversationModel>)model {
    [self GPBSetModel:model];
    NSArray *blockGroups = [[EMClient sharedClient].groupManager getGroupsWithoutPushNotification:nil];
    if ([blockGroups containsObject:model.conversation.conversationId] &&
        model.conversation.type == EMConversationTypeGroupChat && model.conversation.unreadMessagesCount > 0) {
        self.avatarView.badge = NSNotFound;
    }
    else {
        self.avatarView.badge = model.conversation.unreadMessagesCount;
    }
}

@end
