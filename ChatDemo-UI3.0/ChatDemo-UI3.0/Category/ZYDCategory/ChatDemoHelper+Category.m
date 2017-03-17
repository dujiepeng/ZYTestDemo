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
            if ([body.action isEqualToString:@"shareLocation"]) {
                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                if (![msg.ext[ISSTOP] boolValue]) {
                    dic[@"lan"] = msg.ext[LATITUDE];
                    dic[@"lon"] = msg.ext[LONGITUDE];
                }else {
                    dic[@"isStop"] = msg.ext[ISSTOP];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ShareLocations" object:set];
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
        if ([body.action isEqualToString:REVOKE_FLAG]) {
            //删除撤回的消息
            EMConversation *conversation = [[EMClient sharedClient].chatManager getConversation:cmdMessage.conversationId
                                                                                           type:(EMConversationType)cmdMessage.chatType
                                                                               createIfNotExist:YES];
            NSString *revokeMessageId = cmdMessage.ext[MSG_ID];
            //构建插入的消息
            EMMessage *newMessage = [self buildInsertMessageWithConversation:conversation
                                                                  CmdMessage:cmdMessage
                                                                   messageId:revokeMessageId];
            
            
            
            //判断是否删除成功
            BOOL isSuccess = [self removeRevokeMessageWithConversation:conversation
                                                             messageId:revokeMessageId];
            
            if (isSuccess)  { //更新UI,插入一条撤回消息
                
                if (self.chatVC == nil) {
                    self.chatVC = [self _getCurrentChatView];//todo
                }
                BOOL isChatting = NO;
                
                if (self.chatVC)  {
                    
                    isChatting = [cmdMessage.conversationId isEqualToString:self.chatVC.conversation.conversationId];
                    [conversation insertMessage:newMessage error:nil];
                    [conversation deleteMessageWithId:revokeMessageId error:nil];
                    
                    NSInteger index = 0;
                    for (int i = 0; i <= self.chatVC.messsagesSource.count; i++) {
                        index = i;
                        EMMessage *msg = self.chatVC.messsagesSource[i];
                        if ([msg.messageId isEqualToString:revokeMessageId]) {
                            break;
                        }
                    }
                    [self.chatVC.messsagesSource replaceObjectAtIndex:index withObject:newMessage];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.chatVC.messageTimeIntervalTag = 0;
                        NSArray *formattedMessages = (NSArray *)[self.chatVC performSelector:@selector(formatMessages:)
                                                                                  withObject:self.chatVC.messsagesSource];
                        [self.chatVC.dataArray removeAllObjects];
                        [self.chatVC.dataArray addObjectsFromArray:formattedMessages];
                        [self.chatVC.tableView reloadData];
                        [[EMClient sharedClient].chatManager updateMessage:newMessage completion:nil];
                        
                        
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
- (BOOL)removeRevokeMessageWithConversation:(EMConversation *)conversation
                                  messageId:(NSString *)messageId{
    EMError *error = nil;
    [conversation deleteMessageWithId:messageId error:&error];
    return !error;
}

//插入有一条撤回消息
- (EMMessage *)buildInsertMessageWithConversation:(EMConversation *)conversation
                                       CmdMessage:(EMMessage *)cmdMessage
                                        messageId:(NSString *)revokeMessageId{
    
    EMMessage *oldMessage = [conversation loadMessageWithId:revokeMessageId error:nil];
    EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithText:[NSString stringWithFormat:@"%@撤回了一条消息",cmdMessage.from] ];
    NSDictionary *extInsert = @{INSERT:body.text};
    EMMessage *smessage = [[EMMessage alloc] initWithConversationID:oldMessage.conversationId
                                                               from:cmdMessage.from
                                                                 to:oldMessage.conversationId
                                                               body:body ext:extInsert];
    smessage.timestamp = oldMessage.timestamp;
    smessage.localTime = oldMessage.localTime;
    if (conversation.type == EMConversationTypeGroupChat){
        smessage.chatType = EMChatTypeGroupChat;
    } else {
        smessage.chatType = EMChatTypeChat;
    }
    [conversation insertMessage:smessage error:nil];
    return smessage;
}

@end
