//
//  ConversationListController+Revocation.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 14/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "ConversationListController+Revocation.h"
#import "DefineKey.h"
#import <objc/runtime.h>

@implementation ConversationListController (Revocation)
+(void)load {
    Method viewDidLoad = class_getInstanceMethod([self class], @selector(viewDidLoad));
    Method revocationViewDidLoad = class_getInstanceMethod([self class], @selector(revocationViewDidLoad));
    method_exchangeImplementations(viewDidLoad, revocationViewDidLoad);
}

- (void)revocationViewDidLoad {
    [self revocationViewDidLoad];
    [self registerRemoveNotification];
}

#pragma mark - receive
- (void)registerRemoveNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(removeMessageWithMessageId:)
                                                 name:REVOCATION_REFRESHCONVERSATIONS
                                               object:nil];
}

- (void)removeMessageWithMessageId:(NSNotification *)noti {
    EaseConversationModel *needRemoveModel = nil;
    for (EaseConversationModel *model in self.dataArray) {
        EMMessage *msg = model.conversation.latestMessage;
        if (!msg) {
            needRemoveModel = model;
            [[EMClient sharedClient].chatManager deleteConversation:needRemoveModel.conversation.conversationId
                                                   isDeleteMessages:NO
                                                         completion:nil];
        }
    }
    
    if (needRemoveModel) {
        [self.dataArray removeObject:needRemoveModel];
    }
    [self refreshAndSortView];
    [[NSNotificationCenter defaultCenter] postNotificationName:REVOCATION_UPDATE_UNREAD_COUNT object:nil];
}

@end
