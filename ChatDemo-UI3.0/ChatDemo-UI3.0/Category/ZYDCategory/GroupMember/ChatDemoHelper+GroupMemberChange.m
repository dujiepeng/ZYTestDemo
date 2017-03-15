//
//  ChatDemoHelper+GroupMemberChange.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/3/14.
//  Copyright © 2017年 WYZ. All rights reserved.
//

#import "ChatDemoHelper+GroupMemberChange.h"
#import "DefineKey.h"


typedef enum {
    GroupMemberChangeType_Join      =          0,
    GroupMemberChangeType_Leave
}GroupMemberChangeType;

@implementation ChatDemoHelper (GroupMemberChange)

- (void)insertMemberChangeMessage:(EMGroup *)group
                         username:(NSString *)username
                       changeType:(GroupMemberChangeType)type
                          message:(EMMessage **)message{
    
    NSString *msg = nil;
    if (type == GroupMemberChangeType_Join) {
        msg = [NSString stringWithFormat:@"%@加入群组【%@】",username,group.subject];
    }
    else {
        msg = [NSString stringWithFormat:@"%@离开群组【%@】",username,group.subject];
    }
    EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithText:msg];
    EMMessage *_message = [[EMMessage alloc] initWithConversationID:group.groupId
                                                               from:username
                                                                 to:group.groupId
                                                               body:body
                                                                ext:@{GROUP_MEMBER_CHANGE_INSERT:@YES}];
    _message.direction = EMMessageDirectionReceive;
    EMConversation *conversation = [[EMClient sharedClient].chatManager getConversation:group.groupId
                                                                                   type:EMConversationTypeGroupChat
                                                                       createIfNotExist:YES];
    if (conversation.latestMessage) {
        _message.timestamp = conversation.latestMessage.timestamp + 1;
    }
    EMError *error = nil;
    [conversation insertMessage:_message error:&error];
    if (!error) {
        *message = _message;
    }
    else {
        *message = nil;
    }
}

- (void)updateChangePrompt:(EMMessage *)insertMsg {
    
    __block ChatViewController *chatVc = nil;
    [self.mainVC.navigationController.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse
                                                                       usingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[ChatViewController class]]) {
            chatVc = (ChatViewController *)obj;
            *stop = YES;
        }
    }];
    
    if (chatVc &&
        [chatVc.conversation.conversationId isEqualToString:insertMsg.conversationId]) {
        EaseMessageModel *model = [[EaseMessageModel alloc] initWithMessage:insertMsg];
        [chatVc.messsagesSource addObject:insertMsg];
        NSMutableArray *indexPaths = [NSMutableArray array];
        if (chatVc.dataArray.count == 0) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:chatVc.dataArray.count inSection:0]];
            NSDate *messageDate = [NSDate dateWithTimeIntervalInMilliSecondSince1970:(NSTimeInterval)insertMsg.timestamp];
            NSString *timeStr = @"";
            
            if (chatVc.dataSource && [chatVc.dataSource respondsToSelector:@selector(messageViewController:stringForDate:)]) {
                timeStr = [chatVc.dataSource messageViewController:chatVc stringForDate:messageDate];
            }
            else{
                timeStr = [messageDate formattedTime];
            }
            [chatVc.dataArray addObject:timeStr];
            
        }
        [indexPaths addObject:[NSIndexPath indexPathForRow:chatVc.dataArray.count inSection:0]];
        [chatVc.dataArray addObject:model];
        dispatch_async(dispatch_get_main_queue(), ^(){
            [chatVc.tableView beginUpdates];
            [chatVc.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
            [chatVc.tableView endUpdates];
        });
    }
    if (self.conversationListVC) {
        [self.conversationListVC tableViewDidTriggerHeaderRefresh];
    }
}


/*!
 *  \~chinese
 *  有用户加入群组
 *
 *  @param aGroup       加入的群组
 *  @param aUsername    加入者
 *
 *  \~english
 *  Delegate method will be invoked when a user joins a group.
 *
 *  @param aGroup       Joined group
 *  @param aUsername    The user who joined group
 */
- (void)userDidJoinGroup:(EMGroup *)aGroup user:(NSString *)aUsername {
    EMMessage *message = nil;
    [self insertMemberChangeMessage:aGroup
                           username:aUsername
                         changeType:GroupMemberChangeType_Join
                            message:&message];
    if (message) {
        [self updateChangePrompt:message];
    }
}


/*!
 *  \~chinese
 *  有用户离开群组
 *
 *  @param aGroup       离开的群组
 *  @param aUsername    离开者
 *
 *  \~english
 *  Delegate method will be invoked when a user leaves a group.
 *
 *  @param aGroup       Left group
 *  @param aUsername    The user who leaved group
 */
- (void)userDidLeaveGroup:(EMGroup *)aGroup user:(NSString *)aUsername {
    EMMessage *message = nil;
    [self insertMemberChangeMessage:aGroup
                           username:aUsername
                         changeType:GroupMemberChangeType_Leave
                            message:&message];
    if (message) {
        [self updateChangePrompt:message];
    }
}

@end
