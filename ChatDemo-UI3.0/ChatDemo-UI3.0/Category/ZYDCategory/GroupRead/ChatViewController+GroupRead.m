//
//  ChatViewController+GroupRead.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/3/11.
//  Copyright © 2017年 WYZ. All rights reserved.
//

#import "ChatViewController+GroupRead.h"
#import <objc/runtime.h>
#import "LocalDataTools.h"

@implementation ChatViewController (GroupRead)

+ (void)load {
    Method oldBackMethod = class_getInstanceMethod([ChatViewController class], @selector(backAction));
    Method newBackMethod = class_getInstanceMethod([ChatViewController class], @selector(GroupReadBackAction));
    method_exchangeImplementations(oldBackMethod, newBackMethod);
    
    Method oldDeleteMsgMethod = class_getInstanceMethod([ChatViewController class], @selector(deleteMenuAction:));
    Method newDeleteMsgMethod = class_getInstanceMethod([ChatViewController class], @selector(GroupReaddeleteMenuAction:));
    method_exchangeImplementations(oldDeleteMsgMethod, newDeleteMsgMethod);
}

- (void)GroupReadBackAction {
    
    if (self.conversation.type == EMConversationTypeGroupChat) {
        [[LocalDataTools tools] clearCurrentGroupReadItems];
    }
    if (self.deleteConversationIfNull) {
        //判断当前会话是否为空，若符合则删除该会话
        EMMessage *message = [self.conversation latestMessage];
        if (message == nil) {
            [[LocalDataTools tools] removeDataToPlist:self.conversation.conversationId];
        }
    }
    [self GroupReadBackAction];
    
}

- (void)GroupReaddeleteMenuAction:(id)sender
{
    if (self.menuIndexPath && self.menuIndexPath.row > 0) {
        id<IMessageModel> model = [self.dataArray objectAtIndex:self.menuIndexPath.row];
        if (model.isSender) {
            [[LocalDataTools tools] removeDataToPlist:self.conversation.conversationId messageId:model.messageId];
        }
    }
    [self GroupReaddeleteMenuAction:sender];
}

@end
