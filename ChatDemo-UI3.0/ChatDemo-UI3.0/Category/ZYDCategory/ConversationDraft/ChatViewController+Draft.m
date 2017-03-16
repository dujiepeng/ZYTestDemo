//
//  ChatViewController+Draft.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 02/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "ChatViewController+Draft.h"
#import "EaseConversationModel+Top.h"
#import "EMConversation+Draft.h"
#import "ChatDemoHelper.h"
#import "ChatViewController+ShareLocation.h"
#import <objc/runtime.h>

@interface ChatViewController ()<UIAlertViewDelegate,EMClientDelegate>
{
    UIMenuItem *_copyMenuItem;
    UIMenuItem *_deleteMenuItem;
    UIMenuItem *_transpondMenuItem;
    //  UIMenuItem *_retracementMenuItem;//撤回
}

@property (nonatomic, strong) UIMenuItem * retracementMenuItem;//撤回

@end
@implementation ChatViewController (Draft)
+ (void)load {
    Method oldBackMethod = class_getInstanceMethod([ChatViewController class], @selector(backAction));
    Method newBackMethod = class_getInstanceMethod([ChatViewController class], @selector(ZYDBackAction));
    method_exchangeImplementations(oldBackMethod, newBackMethod);
    
    Method oldViewDidLoadMethod = class_getInstanceMethod([ChatViewController class], @selector(viewDidLoad));
    Method newViewDidLoadMethod = class_getInstanceMethod([ChatViewController class], @selector(ZYDViewDidLoad));
    method_exchangeImplementations(oldViewDidLoadMethod, newViewDidLoadMethod);
    
    //添加消息回撤
    Method oldshowMenuViewController = class_getInstanceMethod([ChatViewController class], @selector(showMenuViewController:andIndexPath:messageType:));
    Method newshowMenuViewController = class_getInstanceMethod([ChatViewController class], @selector(ZYDshowMenuViewController:andIndexPath:messageType:));
    method_exchangeImplementations(oldshowMenuViewController, newshowMenuViewController);
}

- (void)ZYDBackAction {
    EaseChatToolbar *toolBar = (EaseChatToolbar *)self.chatToolbar;
    [self.conversation setDraft:toolBar.inputTextView.text];
    
    [[EMClient sharedClient].chatManager removeDelegate:self];
    [[EMClient sharedClient].roomManager removeDelegate:self];
    [[ChatDemoHelper shareHelper] setChatVC:nil];
    
    if (self.deleteConversationIfNull && toolBar.inputTextView.text.length == 0) {
        //判断当前会话是否为空，若符合则删除该会话
        EMMessage *message = [self.conversation latestMessage];
        if (message == nil) {
            [[EMClient sharedClient].chatManager deleteConversation:self.conversation.conversationId isDeleteMessages:NO completion:nil];
        }
    }
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)ZYDViewDidLoad {
    [self ZYDViewDidLoad];
    EaseChatToolbar *toolBar = (EaseChatToolbar *)self.chatToolbar;
    toolBar.inputTextView.text = [self.conversation draft];
}

- (void)ZYDshowMenuViewController:(UIView *)showInView
                     andIndexPath:(NSIndexPath *)indexPath
                      messageType:(EMMessageBodyType)messageType
{
    if (self.menuController == nil) {
        self.menuController = [UIMenuController sharedMenuController];
    }
    
    if (_deleteMenuItem == nil) {
        _deleteMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"delete", @"Delete") action:@selector(deleteMenuAction:)];
    }
    
    if (_copyMenuItem == nil) {
        _copyMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"copy", @"Copy") action:@selector(copyMenuAction:)];
    }
    
    if (_transpondMenuItem == nil) {
        _transpondMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"transpond", @"Transpond") action:@selector(transpondMenuAction:)];
    }
    //撤回
    UIMenuItem *retracementMenuItem;
    if (retracementMenuItem == nil) {
        retracementMenuItem= [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"retracement", @"Retracement")  action:@selector(messageRetracementMenuAction:)];
    }
    
    id<IMessageModel> model = [self.dataArray objectAtIndex:self.menuIndexPath.row];
    
    NSString *currentUsername = [EMClient sharedClient].currentUsername;
    NSString *from = model.message.from;
    
    if ([currentUsername isEqualToString:from]) {
        
        if (messageType == EMMessageBodyTypeText) {
            [self.menuController setMenuItems:@[_copyMenuItem, _deleteMenuItem,_transpondMenuItem,retracementMenuItem]];
        } else if (messageType == EMMessageBodyTypeImage){
            [self.menuController setMenuItems:@[_deleteMenuItem,_transpondMenuItem,retracementMenuItem]];
        } else {
            [self.menuController setMenuItems:@[_deleteMenuItem,retracementMenuItem]];
        }
    }else{
        if (messageType == EMMessageBodyTypeText) {
            [self.menuController setMenuItems:@[_copyMenuItem, _deleteMenuItem,_transpondMenuItem]];
        } else if (messageType == EMMessageBodyTypeImage){
            [self.menuController setMenuItems:@[_deleteMenuItem,_transpondMenuItem]];
        } else {
            [self.menuController setMenuItems:@[_deleteMenuItem]];
        }
    }
    //    UIMenuItem *retracementMenuItem = [[UIMenuItem alloc]init];
    
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
    
    EMCmdMessageBody *body = [[EMCmdMessageBody alloc] initWithAction:@"REVOKE_FLAG"];
    NSDictionary *ext = @{@"msgId":aMessageId};
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
            NSLog(@"发送成功");
            EMMessage *oldMessage = [strongSelf.conversation loadMessageWithId:aMessageId error:nil];
            EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithText:[NSString stringWithFormat:@"%@撤回了一条消息",currentUsername] ];
            EMMessage *smessage = [[EMMessage alloc] initWithConversationID:conversationId from:currentUsername to:conversationId body:body ext:nil];
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
