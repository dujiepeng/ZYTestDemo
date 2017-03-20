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
#import <objc/runtime.h>

#import "DefineKey.h"

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
    BOOL isRefreshCons = YES;
    
    for (EMMessage *cmdMessage in aCmdMessages) {
        EMCmdMessageBody *body = (EMCmdMessageBody *)cmdMessage.body;
        NSString *from = cmdMessage.from;
        
        if ([body.action isEqualToString:@"REVOKE_FLAG"]) {
            //删除撤回的消息
            NSString *revokeMessageId = cmdMessage.ext[@"msgId"];
            
            //构建插入的消息
            EMConversation *conversation = [[EMClient sharedClient].chatManager getConversation:cmdMessage.conversationId
                                                                                           type:(EMConversationType)cmdMessage.chatType
                                                                               createIfNotExist:YES];
            
            EMMessage *oldMessage = [conversation loadMessageWithId:revokeMessageId error:nil];
            EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithText:[NSString stringWithFormat:@"%@撤回了一条消息",cmdMessage.from] ];
            EMMessage *smessage = [[EMMessage alloc] initWithConversationID:oldMessage.conversationId
                                                                       from:from
                                                                         to:oldMessage.conversationId
                                                                       body:body ext:nil];
            smessage.timestamp = oldMessage.timestamp;
            smessage.localTime = oldMessage.localTime;
            if (self.chatVC.conversation.type == EMConversationTypeGroupChat){
                smessage.chatType = EMChatTypeGroupChat;
            } else {
                smessage.chatType = EMChatTypeChat;
            }
            //判断是否删除成功
            BOOL isSuccess = [self removeRevokeMessageWithChatter:cmdMessage.conversationId
                                                 conversationType:(EMConversationType)cmdMessage.chatType
                                                        messageId:revokeMessageId];
            
            if (isSuccess)  { //更新UI,插入一条撤回消息
                
                if (self.chatVC == nil) {
                    self.chatVC = [self _getCurrentChatView];//todo
                }
                BOOL isChatting = NO;
                
                if (self.chatVC)  {
                    
                    isChatting = [cmdMessage.conversationId isEqualToString:self.chatVC.conversation.conversationId];
                    
                    
                    [self.chatVC.conversation insertMessage:smessage error:nil];
                    [self.chatVC.conversation deleteMessageWithId:revokeMessageId error:nil];
                    
                    NSInteger index = 0;
                    for (int i = 0; i <= self.chatVC.messsagesSource.count; i++) {
                        index = i;
                        EMMessage *msg = self.chatVC.messsagesSource[i];
                        if ([msg.messageId isEqualToString:revokeMessageId]) {
                            break;
                        }
                    }
                    
                    [self.chatVC.messsagesSource replaceObjectAtIndex:index withObject:smessage];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.chatVC.messageTimeIntervalTag = 0;
                        NSArray *formattedMessages = (NSArray *)[self.chatVC performSelector:@selector(formatMessages:)
                                                                                  withObject:self.chatVC.messsagesSource];
                        [self.chatVC.dataArray removeAllObjects];
                        [self.chatVC.dataArray addObjectsFromArray:formattedMessages];
                        [self.chatVC.tableView reloadData];
                    });
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
                if (isChatting) {
                    isRefreshCons = NO;
                }
                if (isRefreshCons) {
                    if (self.conversationListVC) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"conversationListRefresh" object:nil];
                    }
                    if (self.contactViewVC) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"setupUnreadMessageCount" object:nil];
                    }
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
