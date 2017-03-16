//
//  ChatDemoHelper+Category.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 27/02/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "ChatDemoHelper+Category.h"
#import "ShareLocationAnnotation.h"
#import "EMConversation+Draft.h"
#import <Hyphenate/Hyphenate.h>
#import "EaseMessageViewController+GroupRead.h"
#import "LocalDataTools.h"
#import <objc/runtime.h>

#import "DefineKey.h"
#import "LocalDataTools.h"

@implementation ChatDemoHelper (Category)
+ (void)load {
    Method oldUpdataMessagesMethod = class_getInstanceMethod([ChatDemoHelper class], @selector(didReceiveMessages:));
    Method newUpdataMessagesMethod = class_getInstanceMethod([ChatDemoHelper class], @selector(ZYDDidReceiveMessages:));
    method_exchangeImplementations(oldUpdataMessagesMethod, newUpdataMessagesMethod);
    
    Method oldConversationListCallbackMethod = class_getInstanceMethod([ChatDemoHelper class], @selector(didUpdateConversationList:));
    Method newConversationListCallbackMethod = class_getInstanceMethod([ChatDemoHelper class], @selector(ZYDDidUpdateConversationList:));
    method_exchangeImplementations(oldConversationListCallbackMethod, newConversationListCallbackMethod);
}

- (void)ZYDDidReceiveMessages:(NSArray *)aMessages{
    NSMutableArray *msgAry = [[NSMutableArray alloc] init];
    NSMutableArray *noticeAry = [[NSMutableArray alloc] init];
    for (EMMessage *msg in aMessages) {
        if ([msg.from isEqualToString:@"admin"] && msg.chatType == EMChatTypeChat) {
            [noticeAry addObject:msg];
        }else {
            [msgAry addObject:msg];
        }
    }
    
    if (noticeAry.count > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"haveReceiveNotices" object:noticeAry];
    }
    
    if (msgAry.count > 0) {
        [self ZYDDidReceiveMessages:msgAry];
    }
}

- (void)cmdMessagesDidReceive:(NSArray *)aCmdMessages {
    NSMutableSet *set = [[NSMutableSet alloc] init];
    for (EMMessage *msg in aCmdMessages) {
        if (msg.body.type == EMMessageBodyTypeCmd) {
            EMCmdMessageBody *body = (EMCmdMessageBody *)msg.body;
            if ([body.action isEqualToString:SHARE_LOCATION_MESSAGE_FLAG]) {
                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                if (![msg.ext[STOP_SHARE_LOCATION_FLAG] boolValue]) {
                    dic[LATITUDE] = msg.ext[LATITUDE];
                    dic[LONGITUDE] = msg.ext[LONGITUDE];
                }else {
                    dic[STOP_SHARE_LOCATION_FLAG] = msg.ext[STOP_SHARE_LOCATION_FLAG];
                }
                dic[@"username"] = msg.from;
                [set addObject:dic];
            }
            else if ([body.action isEqualToString:GROUP_READ_CMD]) {
                //群组消息已读
                NSDictionary *ext = msg.ext;
                NSString *groupId = ext[CURRENT_CONVERSATIONID];
                NSArray *msgIds = ext[UPDATE_MSGID_LIST];
                NSString *readerName = msg.from;
                [[LocalDataTools tools] addDataToPlist:groupId msgIds:msgIds readerName:readerName];
            }
        }
    }
    
    if (set.count > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SHARE_LOCATION_NOTI_KEY object:set];
    }
}

- (void)ZYDDidUpdateConversationList:(NSArray *)aConversationList{
    NSMutableArray *conversationAry = [[NSMutableArray alloc] init];
    for (EMConversation *conversation in aConversationList) {
        if ([conversation.conversationId isEqualToString:@"admin"]) {            
        }else {
            [conversationAry addObject:conversation];
        }
    }
    [self ZYDDidUpdateConversationList:conversationAry];
}

// 接收撤回透传消息
- (void)didReceiveCmdMessages:(NSArray *)aCmdMessages {
    
    for (EMMessage *cmdMessage in aCmdMessages) {
        EMCmdMessageBody *body = (EMCmdMessageBody *)cmdMessage.body;
        NSString *from = cmdMessage.from;
        NSString *to = cmdMessage.to;
        
        if ([body.action isEqualToString:@"REVOKE_FLAG"]) {
            //删除撤回的消息
            NSString *revokeMessageId = cmdMessage.ext[@"msgId"];
            BOOL isSuccess = [self removeRevokeMessageWithChatter:cmdMessage.conversationId conversationType:(EMConversationType)cmdMessage.chatType messageId:revokeMessageId];
            
            if (isSuccess)  {
                
                
                BOOL isChatting = NO;
                
                if (self.chatVC)  {
                    
                    isChatting = [cmdMessage.conversationId isEqualToString:self.chatVC.conversation.conversationId];
                    EMMessage *oldMessage = [self.chatVC.conversation loadMessageWithId:revokeMessageId error:nil];
                    EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithText:[NSString stringWithFormat:@"撤回了一条消息"] ];
                    EMMessage *smessage = [[EMMessage alloc] initWithConversationID:to from:from to:to body:body ext:nil];
                    smessage.timestamp = oldMessage.timestamp;
                    smessage.localTime = oldMessage.localTime;
                    if (self.chatVC.conversation.type == EMConversationTypeGroupChat){
                        smessage.chatType = EMChatTypeGroupChat;
                    } else {
                        smessage.chatType = EMChatTypeChat;
                    }
                    [self.chatVC.conversation insertMessage:smessage error:nil];
                    [self.chatVC.conversation deleteMessageWithId:revokeMessageId error:nil];
                    EaseMessageModel *model = [[EaseMessageModel alloc] initWithMessage:smessage];
                    [self.chatVC.dataArray replaceObjectAtIndex:self.chatVC.menuIndexPath.row withObject:model];
                    __block NSInteger index = -1;
                    [self.chatVC.messsagesSource enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([obj isKindOfClass:[EMMessage class]]) {
                            EMMessage *_message = (EMMessage *)obj;
                            if ([_message.messageId isEqualToString:revokeMessageId]) {
                                index = idx;
                                *stop = YES;
                            }
                        }
                    }];
                    if (index > -1) {
                        [self.chatVC.messsagesSource replaceObjectAtIndex:index withObject:smessage];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.chatVC.tableView beginUpdates];
                        //                        [self.chatVC.tableView reloadRowsAtIndexPaths:@[self.chatVC.menuIndexPath] withRowAnimation:UITableViewRowAnimationNone];
                        [self.chatVC.tableView endUpdates];
                        
                    });
                    [self.chatVC.tableView reloadData];
                    
                }
                else if (self.chatVC == nil || !isChatting) {
                    if (self.conversationListVC) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"conversationListRefresh" object:nil];
                        [self.conversationListVC refresh];
                    }
                    if (self.mainVC) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"conversationListRefresh" object:nil];
                        [self.mainVC setupUnreadMessageCount];
                    }
                    return;
                }
                
            }  else {
                NSLog(@"接收失败");
            }
            
        }
    }
}
//删除消息
- (BOOL)removeRevokeMessageWithChatter:(NSString *)aChatter
                      conversationType:(EMConversationType)type
                             messageId:(NSString *)messageId{
    
    EMConversation *conversation = [[EMClient sharedClient].chatManager getConversation:aChatter type:type createIfNotExist:YES];
    EMError *error = nil;
    [conversation deleteMessageWithId:messageId error:&error];
    return !error;
}


@end
