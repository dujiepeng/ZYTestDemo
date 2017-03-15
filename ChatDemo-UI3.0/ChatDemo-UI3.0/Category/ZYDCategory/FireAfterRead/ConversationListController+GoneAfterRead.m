//
//  ConversationListController+GoneAfterRead.m
//  ChatDemo-UI3.0
//
//  Created by EaseMob on 2017/3/15.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import "ConversationListController+GoneAfterRead.h"
#import <objc/runtime.h>
#import "ChatDemoHelper+GoneAfterRead.h"
@implementation ConversationListController (GoneAfterRead)

+ (void)load
{
    Method latestMessageTitle = class_getInstanceMethod([self class], @selector(conversationListViewController:latestMessageTitleForConversationModel:));
    Method FLatestMessageTitle = class_getInstanceMethod([self class], @selector(FConversationListViewController:latestMessageTitleForConversationModel:));
    method_exchangeImplementations(latestMessageTitle, FLatestMessageTitle);
    
    Method viewDidLoad = class_getInstanceMethod([self class], @selector(viewDidLoad));
    Method FViewDidLoad = class_getInstanceMethod([self class], @selector(FViewDidLoad));
    method_exchangeImplementations(viewDidLoad, FViewDidLoad);
}

- (void)FViewDidLoad
{
    [self FViewDidLoad];

}


/**
 *  最新一条消息为阅后即焚消息时显示
 */
- (NSAttributedString *)FConversationListViewController:(EaseConversationListViewController *)conversationListViewController
                  latestMessageTitleForConversationModel:(id<IConversationModel>)conversationModel
{
    EMMessage *latestMessage = conversationModel.conversation.latestMessage;
    if (latestMessage.ext && [ChatDemoHelper isGoneAfterReadMessage:latestMessage] && (latestMessage.direction == EMMessageDirectionReceive)) {
        
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:@"[阅后即焚消息]"];
        return attr;
    }
    return [self FConversationListViewController:conversationListViewController latestMessageTitleForConversationModel:conversationModel];
}

@end
