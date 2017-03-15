//
//  ChatViewController+InputType.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 09/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "ChatViewController+InputType.h"
#import <objc/runtime.h>
#import <Hyphenate/Hyphenate.h>
@interface ChatViewController () <EMChatManagerDelegate>
@property (nonatomic, strong) NSDate *lastSendDate;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSString *tmpTitle;
@property (nonatomic, assign) NSInteger delayTime;


@end

@implementation ChatViewController (InputType)
static char delayTimeKey;

+(void)load {
    Method oldViewDidLoadMethod = class_getInstanceMethod([ChatViewController class], @selector(viewDidLoad));
    Method newViewDidLoadMethod = class_getInstanceMethod([ChatViewController class], @selector(ZYDInputViewDidLoad));
    method_exchangeImplementations(oldViewDidLoadMethod, newViewDidLoadMethod);
}

- (NSObject *)lastSendDate {
    return objc_getAssociatedObject(self, @selector(lastSendDate));
}

- (void)setLastSendDate:(NSObject *)value {
    objc_setAssociatedObject(self, @selector(lastSendDate), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSObject *)tmpTitle {
    return objc_getAssociatedObject(self, @selector(tmpTitle));
}

- (void)setTmpTitle:(NSObject *)value {
    objc_setAssociatedObject(self, @selector(tmpTitle), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSObject *)timer {
    return objc_getAssociatedObject(self, @selector(timer));
}

- (void)setTimer:(NSObject *)value {
    objc_setAssociatedObject(self, @selector(timer), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger) delayTime{
    return [(NSNumber *)objc_getAssociatedObject(self, &delayTimeKey) integerValue];
}

- (void)setDelayTime:(NSInteger)delayTime{
    objc_setAssociatedObject(self, &delayTimeKey, @(delayTime), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(void)ZYDInputViewDidLoad {
    [self ZYDInputViewDidLoad];
}

- (void)sumDelayTime {
    self.delayTime -= 1;
    if (self.delayTime == 0) {
        [self.timer invalidate];
        self.timer = nil;
        self.title = self.tmpTitle;
    }
}

- (void)cmdMessagesDidReceive:(NSArray *)aCmdMessages {
    for (EMMessage *msg in aCmdMessages) {
        if ([msg.from isEqualToString:self.conversation.conversationId]) {
            if (msg.body.type == EMMessageBodyTypeCmd) {
                EMCmdMessageBody *body = (EMCmdMessageBody *)msg.body;
                if ([body.action isEqualToString:@"inputType"]) {
                    self.delayTime = 5;
                    if (!self.timer) {
                        [self startInputTimer];
                    }
                }
            }
        }
    }
}

- (void)startInputTimer{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self
                                                selector:@selector(sumDelayTime)
                                                userInfo:nil
                                                 repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:UITrackingRunLoopMode];
    self.tmpTitle = self.title;
    self.title = @"对方正在输入...";
}

- (void)inputTypeChange{
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:self.lastSendDate];
    if (self.conversation.type == EMConversationTypeChat) {
        if (!self.lastSendDate || timeInterval >= 5) {
            EMCmdMessageBody *body = [[EMCmdMessageBody alloc] initWithAction:@"inputType"];
            NSString *from = [[EMClient sharedClient] currentUsername];
            EMMessage *message = [[EMMessage alloc] initWithConversationID:self.conversation.conversationId
                                                                      from:from
                                                                        to:self.conversation.conversationId
                                                                      body:body
                                                                       ext:nil];
            message.chatType = EMChatTypeChat;
            [[EMClient sharedClient].chatManager sendMessage:message progress:nil completion:nil];
            self.lastSendDate = [NSDate date];
        }
    }
}

@end
