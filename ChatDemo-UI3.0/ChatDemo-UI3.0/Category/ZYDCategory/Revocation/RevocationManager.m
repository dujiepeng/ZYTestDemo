//
//  RevocationManager.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 14/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "RevocationManager.h"
#import "DefineKey.h"
#import <Hyphenate/Hyphenate.h>

@interface RevocationManager () <EMChatManagerDelegate>

@end

@implementation RevocationManager

+ (RevocationManager *)sharedInstance {
    static RevocationManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[RevocationManager alloc] init];
    });
    
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        [[EMClient sharedClient].chatManager addDelegate:self delegateQueue:nil];
    }
    
    return self;
}

- (void)cmdMessagesDidReceive:(NSArray *)aCmdMessages {
    for (EMMessage *msg in aCmdMessages) {
        
        if ([msg.ext[REVOCATION] boolValue]) {
            [self postNotiToRemoveMessageWithMessageId:msg];
        }
    }
}

- (void)postNotiToRemoveMessageWithMessageId:(EMMessage *)aMessage {
    // 不在聊天页面的删除
    if (!self.chatVC) {
        EMConversationType type = EMConversationTypeChat;
        if(aMessage.chatType == EMChatTypeGroupChat) {
            type = EMConversationTypeGroupChat;
        }
        EMConversation *con = [[EMClient sharedClient].chatManager getConversation:aMessage.conversationId type:type createIfNotExist:NO];
        if (con) {
            EMCmdMessageBody *body = (EMCmdMessageBody *)aMessage.body;
            [con deleteMessageWithId:body.action error:nil];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:REVOCATION_REFRESHCONVERSATIONS object:aMessage];
    }else {
        [[NSNotificationCenter defaultCenter] postNotificationName:REVOCATION_DELETE object:aMessage];
    }
}

@end
