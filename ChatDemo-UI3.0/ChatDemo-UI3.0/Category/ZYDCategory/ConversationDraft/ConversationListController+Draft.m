//
//  ConversationListController+Draft.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 02/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "ConversationListController+Draft.h"
#import "EMConversation+Draft.h"
#import "EaseConversationModel+Top.h"
#import <objc/runtime.h>

@implementation ConversationListController (Draft)

+(void)load {
    Method old = class_getInstanceMethod([self class], @selector(removeEmptyConversationsFromDB));
    Method new = class_getInstanceMethod([self class], @selector(ZYDRmoveEmptyConversationsFromDB));
    method_exchangeImplementations(old, new);
}

- (void)ZYDRmoveEmptyConversationsFromDB {
    NSArray *conversations = [[EMClient sharedClient].chatManager getAllConversations];
    NSMutableArray *needRemoveConversations;
    for (EMConversation *conversation in conversations) {
        if (!conversation.latestMessage || (conversation.type == EMConversationTypeChatRoom)) {
            if (!needRemoveConversations) {
                needRemoveConversations = [[NSMutableArray alloc] initWithCapacity:0];
            }
            
            if (conversation.draft && conversation.draft.length > 0) {
                continue;
            }
            
            [needRemoveConversations addObject:conversation];
        }
    }
    
    if (needRemoveConversations && needRemoveConversations.count > 0) {
        [[EMClient sharedClient].chatManager deleteConversations:needRemoveConversations isDeleteMessages:YES completion:nil];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EaseConversationCell *cell = (EaseConversationCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    EaseConversationModel *model = cell.model;
    if (model.conversation.draft && model.conversation.draft.length > 0) {
        cell.detailLabel.text = [NSString stringWithFormat:@"[草稿]%@",model.conversation.draft];
    }
    
    return cell;
}
@end
