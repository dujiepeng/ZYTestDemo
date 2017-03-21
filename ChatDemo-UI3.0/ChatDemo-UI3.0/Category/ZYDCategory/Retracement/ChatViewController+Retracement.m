//
//  ChatViewController+Retracement.m
//  ChatDemo-UI3.0
//
//  Created by 蒋月婷 on 17/3/17.
//  Copyright © 2017年 蒋月婷. All rights reserved.
//

#import "ChatViewController+Retracement.h"

#import "ChatViewController+Draft.h"
#import "EaseConversationModel+Top.h"
#import "EMConversation+Draft.h"
#import "ChatDemoHelper.h"
#import "ChatViewController+ShareLocation.h"
#import <objc/runtime.h>
#import "DefineKey.h"

@interface ChatViewController ()<UIAlertViewDelegate,EMClientDelegate>
{
    UIMenuItem *_copyMenuItem;
    UIMenuItem *_deleteMenuItem;
    UIMenuItem *_transpondMenuItem;
}

@property (nonatomic, strong) UIMenuItem * retracementMenuItem;//撤回
;

@end
@implementation ChatViewController (Retracement)
+ (void)load {
    
    Method oldshowMenuViewController = class_getInstanceMethod([ChatViewController class], @selector(showMenuViewController:andIndexPath:messageType:));
    Method newshowMenuViewController = class_getInstanceMethod([ChatViewController class], @selector(ZYDshowMenuViewController:andIndexPath:messageType:));
    method_exchangeImplementations(oldshowMenuViewController, newshowMenuViewController);
}

- (void)ZYDshowMenuViewController:(UIView *)showInView
                     andIndexPath:(NSIndexPath *)indexPath
                      messageType:(EMMessageBodyType)messageType
{
    if (self.menuController == nil) {
        self.menuController = [UIMenuController sharedMenuController];
    }
    
    if (_deleteMenuItem == nil) {
        _deleteMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"delete", @"Delete")
                                                     action:@selector(deleteMenuAction:)];
    }
    
    if (_copyMenuItem == nil) {
        _copyMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"copy", @"Copy")
                                                   action:@selector(copyMenuAction:)];
    }
    
    if (_transpondMenuItem == nil) {
        _transpondMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"transpond", @"Transpond")
                                                        action:@selector(transpondMenuAction:)];
    }
    //撤回
    UIMenuItem *retracementMenuItem;
    if (retracementMenuItem == nil) {
        retracementMenuItem= [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"retracement", @"Retracement")
                                                        action:@selector(messageRetracementMenuAction:)];
    }
    
    id<IMessageModel> model = [self.dataArray objectAtIndex:self.menuIndexPath.row];
    BOOL isFireMsg = [[model.message.ext objectForKey:kGoneAfterReadKey] boolValue];
    NSMutableArray *items = [NSMutableArray array];
    if (!isFireMsg) {
        switch (messageType) {
            case EMMessageBodyTypeText:
            {
                [items addObject:_copyMenuItem];
            }
            case EMMessageBodyTypeImage:
            case EMMessageBodyTypeVideo:
            {
                [items addObject:_transpondMenuItem];
            }
            case EMMessageBodyTypeVoice:
            case EMMessageBodyTypeFile:
            case EMMessageBodyTypeLocation:
            {
         
            }
                break;
            default:
                break;
        }
    }
    
    [items addObject:_deleteMenuItem];
    
    NSString *currentUsername = [EMClient sharedClient].currentUsername;
    NSString *from = model.message.from;
    if ([currentUsername isEqualToString:from]) {
        [items addObject:retracementMenuItem];
    }
    
    [self.menuController setMenuItems:items];
    [self.menuController setTargetRect:showInView.frame inView:showInView.superview];
    [self.menuController setMenuVisible:YES animated:YES];
}


//实现这个回撤的方法 ，在两分钟内撤回，超过两分钟提示
- (void)messageRetracementMenuAction:(id)sender {
    
    if (self.menuIndexPath && self.menuIndexPath.row > 0) {
        id<IMessageModel> model = [self.dataArray objectAtIndex:self.menuIndexPath.row];
        NSString *messageId  = model.message.messageId;
        // 发送这条消息在服务器的时间戳
        NSTimeInterval time1 = (model.message.timestamp) / 1000.0;
        // 当前的时间戳
        NSTimeInterval nowTime = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval cha = nowTime - time1;
        NSInteger timecha = cha;
        if (timecha <= 120) {
            // 开始调用发送消息回撤的方法
            [self revokeMessageWithMessageId:messageId conversationId:self.conversation.conversationId ];
        } else {
            [self showHint:@"消息已经超过两分钟 无法撤回"];
        }
    }
}
//发送回撤的透传消息  删除 self.conversation，self.dataArray，self.messsagesSource，这三个，然后刷新一下。
- (void)revokeMessageWithMessageId:(NSString *)aMessageId   conversationId:(NSString *)conversationId {
    
    if (!self.menuIndexPath) {
        return;
    }
    
    EMCmdMessageBody *body = [[EMCmdMessageBody alloc] initWithAction:REVOKE_FLAG];
    NSDictionary *ext = @{MSG_ID:aMessageId};
    NSString *currentUsername = [EMClient sharedClient].currentUsername;
    EMMessage *message = [[EMMessage alloc] initWithConversationID:conversationId from:currentUsername  to:conversationId body:body ext:ext];
    
    if (self.conversation.type == EMConversationTypeGroupChat){
        message.chatType = EMChatTypeGroupChat;
    } else {
        message.chatType = EMChatTypeChat;
    }
    
    __weak typeof(self) weakSelf = self;
    //发送cmd消息
    [[EMClient sharedClient].chatManager sendMessage:message progress:nil completion:^(EMMessage *message, EMError *error) {
        if (!error) {
            __strong typeof(ChatViewController) *strongSelf = weakSelf;
            NSLog(@"发送成功 %@",aMessageId);
            EMMessage *oldMessage = [strongSelf.conversation loadMessageWithId:aMessageId error:nil];
            
            EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithText:[NSString stringWithFormat:@"%@撤回了一条消息",currentUsername] ];
            NSDictionary *extInsert = @{INSERT:body.text};
            
            EMMessage *smessage = [[EMMessage alloc] initWithConversationID:conversationId
                                                                       from:currentUsername
                                                                         to:conversationId body:body
                                                                        ext:extInsert];
            smessage.timestamp = oldMessage.timestamp;
            smessage.localTime = oldMessage.localTime;
            
            
            if (strongSelf.conversation.type == EMConversationTypeGroupChat){
                smessage.chatType = EMChatTypeGroupChat;
            } else {
                smessage.chatType = EMChatTypeChat;
            }
            [strongSelf.conversation insertMessage:smessage error:nil];
            [strongSelf.conversation deleteMessageWithId:aMessageId error:nil];
            
            EaseMessageModel *model = [[EaseMessageModel alloc] initWithMessage:smessage];
            [strongSelf.dataArray replaceObjectAtIndex:self.menuIndexPath.row withObject:model];
            
            __block NSInteger index = -1;
            NSLock *mutexLock;
            [mutexLock lock];

            [strongSelf.messsagesSource enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[EMMessage class]]) {
                    EMMessage *_message = (EMMessage *)obj;
                    if ([_message.messageId isEqualToString:aMessageId]) {
                        index = idx;
                        *stop = YES;
                    }
                }
            }];
            if (index > -1) {
                [strongSelf.messsagesSource replaceObjectAtIndex:index withObject:smessage];
            }
            [mutexLock unlock];

            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf.tableView beginUpdates];
                [strongSelf.tableView reloadRowsAtIndexPaths:@[self.menuIndexPath] withRowAnimation:UITableViewRowAnimationNone];
                [strongSelf.tableView endUpdates];
                
            });
            
            
            
        }  else {
            NSLog(@"发送失败");
        }
    }];
}
@end
