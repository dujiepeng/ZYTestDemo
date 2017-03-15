//
//  ChatViewController+Revocation.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 14/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "ChatViewController+Revocation.h"
#import "DefineKey.h"
#import "RevocationManager.h"
#import <objc/runtime.h>

#define TIMESTAMPE 120000

@interface ChatViewController ()
{
    UIMenuItem *_revocationMenuItem;
}

@end

@implementation ChatViewController (Revocation)

+(void)load {
    Method old = class_getInstanceMethod([self class], @selector(showMenuViewController:andIndexPath:messageType:));
    Method new = class_getInstanceMethod([self class], @selector(ZYDShowMenuViewController:andIndexPath:messageType:));
    method_exchangeImplementations(old, new);
    
    Method viewDidLoad = class_getInstanceMethod([self class], @selector(viewDidLoad));
    Method revocationViewDidLoad = class_getInstanceMethod([self class], @selector(revocationViewDidLoad));
    method_exchangeImplementations(viewDidLoad, revocationViewDidLoad);
    
    Method oldBackMethod = class_getInstanceMethod([ChatViewController class], @selector(backAction));
    Method newBackMethod = class_getInstanceMethod([ChatViewController class], @selector(revocationBackAction));
    method_exchangeImplementations(oldBackMethod, newBackMethod);
}

- (void)revocationViewDidLoad {
    [self revocationViewDidLoad];
    [self registerRemoveNotification];
    [RevocationManager sharedInstance].chatVC = self;
}

- (void)revocationBackAction {
    [RevocationManager sharedInstance].chatVC = nil;
    [self revocationBackAction];
}

- (void)ZYDShowMenuViewController:(UIView *)showInView andIndexPath:(NSIndexPath *)indexPath
                      messageType:(EMMessageBodyType)messageType {
    
    if (self.menuController == nil) {
        self.menuController = [UIMenuController sharedMenuController];
    }
    
    if ([self valueForKey:@"_deleteMenuItem"] == nil) {
        UIMenuItem *deleteMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"delete", @"Delete")
                                                                action:@selector(deleteMenuAction:)];
        [self setValue:deleteMenuItem forKey:@"_deleteMenuItem"];
    }
    
    if ([self valueForKey:@"_copyMenuItem"] == nil) {
        UIMenuItem *copyMenuItem = [[UIMenuItem alloc] initWithTitle:NSEaseLocalizedString(@"copy", @"Copy")
                                                              action:@selector(copyMenuAction:)];
        [self setValue:copyMenuItem forKey:@"_copyMenuItem"];
    }
    
    if ([self valueForKey:@"_transpondMenuItem"] == nil) {
        UIMenuItem *transpondMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"transpond", @"Transpond")
                                                                   action:@selector(transpondMenuAction:)];
        [self setValue:transpondMenuItem forKey:@"_transpondMenuItem"];
    }
    
    UIMenuItem *revocationMenuItem = [[UIMenuItem alloc] initWithTitle:@"撤回"
                                                                action:@selector(revocationMenuAction:)];
    
    id copy = [self valueForKey:@"_copyMenuItem"];
    id delete = [self valueForKey:@"_deleteMenuItem"];
    id transpond = [self valueForKey:@"_transpondMenuItem"];
    id revocation = revocationMenuItem;
    
    NSMutableArray *menuItems = [NSMutableArray array];
    
    EaseMessageModel *model = [self.dataArray objectAtIndex:indexPath.row];
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970] * 1000;
    
    // 发送方、120秒内、单聊
    if (model.isSender && timeInterval - model.message.timestamp < TIMESTAMPE && model.messageType != EMChatTypeChatRoom) {
        [menuItems addObject:revocation];
    }
    
    if (messageType == EMMessageBodyTypeText) {
        [menuItems addObject:copy];
        [menuItems addObject:delete];
        [menuItems addObject:transpond];
    } else if (messageType == EMMessageBodyTypeImage || messageType == EMMessageBodyTypeVideo){
        [menuItems addObject:delete];
        [menuItems addObject:transpond];
    } else {
        [menuItems addObject:delete];
    }
    
    [self.menuController setMenuItems:menuItems];
    [self.menuController setTargetRect:showInView.frame inView:showInView.superview];
    [self.menuController setMenuVisible:YES animated:YES];
}

#pragma mark - send
- (void) revocationMenuAction:(id)sender {
    if (self.menuIndexPath && self.menuIndexPath.row > 0) {
        EaseMessageModel *model = (EaseMessageModel *)[self.dataArray objectAtIndex:self.menuIndexPath.row];
        EMCmdMessageBody *body = [[EMCmdMessageBody alloc] initWithAction:model.messageId];
        NSString *from = [[EMClient sharedClient] currentUsername];
        EMMessage *message = [[EMMessage alloc] initWithConversationID:self.conversation.conversationId
                                                                  from:from
                                                                    to:self.conversation.conversationId
                                                                  body:body
                                                                   ext:nil];
        message.ext = @{REVOCATION:@YES};
        message.chatType = EMChatTypeChat;
        if (self.conversation.type == EMChatTypeGroupChat) {
            message.chatType = EMChatTypeGroupChat;
        }
        
        [[EMClient sharedClient].chatManager sendMessage:message progress:nil completion:nil];
    }
    
    [self performSelector:@selector(deleteMenuAction:) withObject:sender];
}

#pragma mark - receive
- (void)registerRemoveNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(removeMessageWithMessageId:)
                                                 name:REVOCATION_DELETE
                                               object:nil];
}

- (void)removeMessageWithMessageId:(NSNotification *)noti {
    EMMessage *cmdMsg = (EMMessage *)noti.object;
    EMCmdMessageBody *body = (EMCmdMessageBody *)cmdMsg.body;
    EMMessage *msg = [self.conversation loadMessageWithId:body.action error:nil];
    if (msg) {
        EMMessage *needRemoveMsg = nil;
        for (EMMessage *msg in self.messsagesSource) {
            if ([msg.messageId isEqualToString:body.action]) {
                needRemoveMsg = msg;
                break;
            }
        }
        
        if (needRemoveMsg) {
            [self.conversation deleteMessageWithId:needRemoveMsg.messageId error:nil];
            self.messageTimeIntervalTag = 0;
            [self.messsagesSource removeObject:needRemoveMsg];
            NSArray *formattedMessages = (NSArray *)[self performSelector:@selector(formatMessages:)
                                                               withObject:self.messsagesSource];
            [self.dataArray removeAllObjects];
            [self.dataArray addObjectsFromArray:formattedMessages];
            [self.tableView reloadData];
        }
    }
}

@end
