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



@end
