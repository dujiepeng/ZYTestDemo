//
//  EaseFireHelper.m
//  ChatDemo-UI3.0
//
//  Created by EaseMob on 2017/3/17.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import "EaseFireHelper.h"
#import <objc/runtime.h>

#define kGoneAfterReadKey @"goneAfterReadKey"
/** @brief NSUserDefaults中保存当前已阅读但未发送ack回执的阅后即焚消息信息 */
#define NEED_REMOVE_MESSAGE_DIC            @"em_needRemoveMessages"
/** @brief 已读阅后即焚消息在NSUserDefaults保存的key前缀 */
#define KEM_REMOVEAFTERREAD_PREFIX                @"readFirePrefix"
//需要发送ack的阅后即焚消息信息在NSUserDefaults中的存放key
#define UserDefaultKey(username) [[KEM_REMOVEAFTERREAD_PREFIX stringByAppendingString:@"_"] stringByAppendingString:username]
/** @brief NSUserDefaults中保存当前阅读的阅后即焚消息信息 */
#define NEED_REMOVE_CURRENT_MESSAGE        @"em_needRemoveCurrnetMessage"
#define kReconnectAction @"RemoveUnFiredMsg"
#define kReconnectMsgIdKey @"REMOVE_UNFIRED_MSG"
@interface EaseFireHelper()<EMClientDelegate, EMChatManagerDelegate>
@property (nonatomic, strong) NSDictionary *infoDic;
@property (nonatomic, strong) dispatch_queue_t queue;
@end

static EaseFireHelper *helper = nil;
@implementation EaseFireHelper
+ (instancetype)sharedHelper
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        helper = [[EaseFireHelper alloc] init];
    });
    return helper;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[EMClient sharedClient] addDelegate:self delegateQueue:nil];
        [[EMClient sharedClient].chatManager addDelegate:self delegateQueue:nil];
    }
    return self;
}

- (NSDictionary *)needRemoveDic
{
    return [self.infoDic objectForKey:NEED_REMOVE_MESSAGE_DIC];
}

#pragma mark - 阅后即焚ext

// 构造消息的ext
+ (NSDictionary *)structureGoneAfterReadMsgExt:(NSDictionary *)ext
{
    NSMutableDictionary *tempExt = [ext mutableCopy];
    if (!tempExt) {
        
        tempExt = [NSMutableDictionary dictionary];
    }
    [tempExt setObject:@YES forKey:kGoneAfterReadKey];
    return tempExt;
}
// 判断是否为阅后即焚消息
+ (BOOL)isGoneAfterReadMessage:(EMMessage *)message
{
    return [[message.ext objectForKey:kGoneAfterReadKey] boolValue];
}

#pragma mark - 处理阅后即焚消息

- (void)handleGoneAfterReadMessage:(EMMessage *)message
{
    if (!message) {
        return;
    }
    self.queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(self.queue, ^{
        
        EMConversation *conversation = [[EMClient sharedClient].chatManager getConversation:message.conversationId type:EMConversationTypeChat createIfNotExist:YES];
        if (![message.from isEqualToString:[[EMClient sharedClient] currentUsername]]) {
            
            if ([[EMClient sharedClient] isConnected]) {
                
                EMError *aError = nil;
                [conversation deleteMessageWithId:message.messageId error:&aError];
                if (!aError) {
                    
                    // 发送已读回执
                    [conversation markMessageAsReadWithId:message.messageId error:nil];
                    [self sendRemoveMessageAction:message];
                    
                } else {
                    
                    [self addMessageToNeedRemoveDic:@[message.conversationId, message.messageId]];
                }
                if (!conversation.latestMessage) {
                    
                    [[EMClient sharedClient].chatManager deleteConversation:conversation.conversationId isDeleteMessages:YES completion:^(NSString *aConversationId, EMError *aError) {
                        
                        [self.conversationListVC tableViewDidTriggerHeaderRefresh];
                    }];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"handleGoneAfterReadUI" object:message];
                });
            }
        }
    });
}

- (void)messagesDidRead:(NSArray *)aMessages
{
    for (EMMessage *msg in aMessages) {
        
        if ([EaseFireHelper isGoneAfterReadMessage:msg]) {
            
            EMConversation *conversation = [[EMClient sharedClient].chatManager getConversation:msg.conversationId type:EMConversationTypeChat createIfNotExist:YES];
            [conversation deleteMessageWithId:msg.messageId error:nil];
            if (!conversation.latestMessage) {
                
                [[EMClient sharedClient].chatManager deleteConversation:conversation.conversationId isDeleteMessages:YES completion:nil];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"handleGoneAfterReadUI" object:msg];
            });
            
        }
    }
}

- (void)connectionStateDidChange:(EMConnectionState)aConnectionState
{
    if (aConnectionState == EMConnectionConnected && [[EMClient sharedClient] isLoggedIn]) {
        NSLog(@"------%s-----",__func__);
        [self addMessageToNeedRemoveDic:self.infoDic[NEED_REMOVE_CURRENT_MESSAGE]];
        [self sendAllNeedRemoveMessage];
    }
}

- (void)autoLoginDidCompleteWithError:(EMError *)aError
{
    if (!aError) {
        
        if ([[EMClient sharedClient] isLoggedIn]) {
            
            NSLog(@"------%s-----",__func__);
            [self addMessageToNeedRemoveDic:self.infoDic[NEED_REMOVE_CURRENT_MESSAGE]];
            [self sendAllNeedRemoveMessage];
        }
    }
}





#pragma mark - Other

- (void)updateCurrentMsg:(EMMessage *)aMessage
{
    if (!aMessage)
    {
        return;
    }
    NSMutableDictionary *dic = [self.infoDic mutableCopy];
    if (!dic) {
        dic = [[NSMutableDictionary alloc] init];
    }
    dic[NEED_REMOVE_CURRENT_MESSAGE] = @[aMessage.conversationId,aMessage.messageId];
    [self updateInfoDic:dic];
}

- (void)updateInfoDic:(NSDictionary *)dic
{
    @synchronized(self) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if ([[EMClient sharedClient] currentUsername].length > 0) {
            
            if (dic) {
                [userDefaults setObject:dic forKey:UserDefaultKey([[EMClient sharedClient] currentUsername])];
            }else {
                [userDefaults removeObjectForKey:UserDefaultKey([[EMClient sharedClient] currentUsername])];
            }
            [userDefaults synchronize];
        }
        self.infoDic = dic;
    }
}

- (void)addMessageToNeedRemoveDic:(NSArray *)messageInfo
{
    if (!messageInfo && messageInfo.count != 2)
    {
        return;
    }
    NSMutableDictionary *needRemoveDic = [[self needRemoveDic] mutableCopy];
    if (!needRemoveDic) {
        needRemoveDic = [[NSMutableDictionary alloc] init];
    }
    NSMutableArray *needRemoveAry = [needRemoveDic[messageInfo.firstObject] mutableCopy];
    if (!needRemoveAry) {
        needRemoveAry = [[NSMutableArray alloc] init];
    }
    [needRemoveAry addObject:messageInfo.lastObject];
    needRemoveDic[messageInfo.firstObject] = needRemoveAry;
    NSMutableDictionary *dic = [self.infoDic mutableCopy];
    dic[NEED_REMOVE_MESSAGE_DIC] = needRemoveDic;
    NSArray *currentMessageInfo = [dic[NEED_REMOVE_CURRENT_MESSAGE] mutableCopy];
    if (currentMessageInfo && currentMessageInfo.count == 2)
    {//如果已存储的 当前阅读消息，与传入的相同，则清除(此时 信息已经转存到 待发送ack的消息字典中)
        if ([currentMessageInfo.firstObject isEqualToString:messageInfo.firstObject] &&
            [currentMessageInfo.lastObject isEqualToString:messageInfo.lastObject])
        {
            [dic removeObjectForKey:NEED_REMOVE_CURRENT_MESSAGE];
        }
    }
    [self updateInfoDic:dic];
}

- (void)sendRemoveMessageAction:(EMMessage *)aMessage
{
    __weak typeof(self) weakSelf = self;
    self.queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(self.queue, ^{
        if ([[EMClient sharedClient] isConnected]) {
            
            [[EMClient sharedClient].chatManager sendMessageReadAck:aMessage completion:^(EMMessage *aMessage, EMError *aError) {
                
            }];
            NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
            NSMutableDictionary *dic = [[userDefault objectForKey:UserDefaultKey([[EMClient sharedClient] currentUsername])] mutableCopy];
            if (!dic) {
                dic = [[NSMutableDictionary alloc] init];
            }
            [dic removeObjectForKey:NEED_REMOVE_CURRENT_MESSAGE];
            [weakSelf updateInfoDic:dic];
        }else {
            [weakSelf addMessageToNeedRemoveDic:@[aMessage.conversationId,aMessage.messageId]];
        }
    });
    
}

/**
 * 为NSUserDefaults记录的已读阅后即焚消息发送ack回执，并删除该消息
 *
 */
- (void)sendAllNeedRemoveMessage{
    __weak typeof(self) weakSelf = self;
    self.queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(self.queue, ^{
        if ([[EMClient sharedClient] isConnected]) {
            for (NSString *chatter in [weakSelf.needRemoveDic allKeys]) {
                
                EMConversation *conversation = [[EMClient sharedClient].chatManager getConversation:chatter type:EMConversationTypeChat createIfNotExist:YES];
                for (NSString *messageId in weakSelf.needRemoveDic[chatter]) {
                    
                    EMMessage *msg = [conversation loadMessageWithId:messageId error:nil];
                    if (!msg) {
                        
                        EMCmdMessageBody *cmd = [[EMCmdMessageBody alloc] initWithAction:@"RemoveUnFiredMsg"];
                        EMMessage *msg = [[EMMessage alloc] initWithConversationID:chatter from:[[EMClient sharedClient] currentUsername] to:chatter body:cmd ext:@{@"REMOVE_UNFIRED_MSG":messageId}];
                        [[EMClient sharedClient].chatManager sendMessage:msg progress:nil completion:nil];
                    } else {
                        
                        [[EMClient sharedClient].chatManager sendMessageReadAck:msg completion:nil];
                        [conversation deleteMessageWithId:msg.messageId error:nil];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"handleGoneAfterRead" object:msg];
                    });
                }
                if (!conversation.latestMessage)
                {
                    [[EMClient sharedClient].chatManager deleteConversation:conversation.conversationId isDeleteMessages:YES completion:nil];
                    [weakSelf.conversationListVC tableViewDidTriggerHeaderRefresh];

                }
            }
            [weakSelf clearNeedRemoveDic];
        }
    });
}

/**
 * 清除需要发送ack消息的记录
 *
 */
- (void)clearNeedRemoveDic{
    NSMutableDictionary *dic = [self.infoDic mutableCopy];
    [dic removeObjectForKey:NEED_REMOVE_MESSAGE_DIC];
    [self updateInfoDic:dic];
}

- (void)cmdMessagesDidReceive:(NSArray *)aCmdMessages
{
    for (EMMessage *msg in aCmdMessages) {
        
        EMCmdMessageBody *body = (EMCmdMessageBody *)msg.body;
        if (![body.action isEqualToString:kReconnectAction]) {
            continue;
        }
        NSString *msgId = msg.ext[kReconnectMsgIdKey];
        if (msgId.length > 0) {
            
            EMConversation *conversation = [[EMClient sharedClient].chatManager getConversation:msg.conversationId type:EMConversationTypeChat createIfNotExist:YES];
            EMMessage *message = [conversation loadMessageWithId:msgId error:nil];
            [conversation deleteMessageWithId:msgId error:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"handleGoneAfterReadUI" object:message];
            if (!conversation.latestMessage) {
                
                [self.conversationListVC tableViewDidTriggerHeaderRefresh];
            }
            
        }
        
    }
}

@end
