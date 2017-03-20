//
//  ChatDemoHelper+Retracement.m
//  ChatDemo-UI3.0
//
//  Created by 蒋月婷 on 17/3/20.
//  Copyright © 2017年 蒋月婷. All rights reserved.
//

#import "ChatDemoHelper+Retracement.h"
#import "DefineKey.h"

@implementation ChatDemoHelper (Retracement)

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
