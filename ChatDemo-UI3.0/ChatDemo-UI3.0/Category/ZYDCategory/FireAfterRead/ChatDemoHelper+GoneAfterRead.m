//
//  ChatDemoHelper+GoneAfterRead.m
//  ChatDemo-UI3.0
//
//  Created by EaseMob on 2017/3/14.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import "ChatDemoHelper+GoneAfterRead.h"
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

@interface ChatDemoHelper()

@property (nonatomic, strong) NSDictionary *infoDic;
@property (nonatomic, strong) dispatch_queue_t queue;


@end

static const char *goneModeKey = "goneModeKey";
static char infoDicKey;
static char queueKey;
@implementation ChatDemoHelper (GoneAfterRead)

- (BOOL)isGoneAfterReadMode
{
    return [objc_getAssociatedObject(self, goneModeKey) boolValue];
}

- (void)setIsGoneAfterReadMode:(BOOL)isGoneAfterReadMode
{
    objc_setAssociatedObject(self, goneModeKey,  @(isGoneAfterReadMode), OBJC_ASSOCIATION_ASSIGN);
}

- (NSDictionary *)needRemoveDic
{
    return [self.infoDic objectForKey:NEED_REMOVE_MESSAGE_DIC];
}

- (NSDictionary *)infoDic
{
    return objc_getAssociatedObject(self, &infoDicKey);
}

- (void)setInfoDic:(NSDictionary *)infoDic
{
    objc_setAssociatedObject(self, &infoDicKey, infoDic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (dispatch_queue_t)queue
{
    return objc_getAssociatedObject(self, &queueKey);
}

- (void)setQueue:(dispatch_queue_t)queue
{
    objc_setAssociatedObject(self, &queueKey, queue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)hasGone
{
    return [objc_getAssociatedObject(self, @selector(hasGone)) boolValue];
}

- (void)setHasGone:(BOOL)hasGone
{
    objc_setAssociatedObject(self, @selector(hasGone), @(hasGone), OBJC_ASSOCIATION_ASSIGN);
}

/**
 构造阅后即焚ext
 */
+ (NSDictionary *)structureGoneAfterReadMsgExt:(NSDictionary *)ext
{
    NSMutableDictionary *tempExt = [ext mutableCopy];
    if (!tempExt) {
        
        tempExt = [NSMutableDictionary dictionary];
    }
    [tempExt setObject:@YES forKey:kGoneAfterReadKey];
    return tempExt;
}

+ (BOOL)isGoneAfterReadMessage:(EMMessage *)message
{
    return [[message.ext objectForKey:kGoneAfterReadKey] boolValue];
}

- (void)updateCurrentMsg:(EMMessage *)aMessage{
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

- (void)updateInfoDic:(NSDictionary *)dic{
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
                    [[EMClient sharedClient].chatManager sendMessageReadAck:msg completion:nil];
                    [conversation deleteMessageWithId:msg.messageId error:nil];
                }
                if (!conversation.latestMessage)
                {
                    [[EMClient sharedClient].chatManager deleteConversation:conversation.conversationId isDeleteMessages:YES completion:nil];
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

#pragma mark - EMClientDelegate

- (void)messagesDidRead:(NSArray *)aMessages
{
    for (EMMessage *msg in aMessages) {
        
        if ([ChatDemoHelper isGoneAfterReadMessage:msg]) {
            
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


@end
