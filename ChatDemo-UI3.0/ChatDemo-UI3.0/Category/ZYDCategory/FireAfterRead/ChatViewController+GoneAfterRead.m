//
//  ChatViewController+GoneAfterRead.m
//  ChatDemo-UI3.0
//
//  Created by EaseMob on 2017/3/14.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import "ChatViewController+GoneAfterRead.h"
#import "ChatDemoHelper+GoneAfterRead.h"
#import <objc/runtime.h>
#import "EaseMessageReadManager+GoneAfterRead.h"

@interface ChatViewController()<EaseMessageReadManagerDelegate>

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) id<IMessageModel>currentModel;
@property (nonatomic, strong) NSRunLoop *runloop;
@end

@implementation ChatViewController (GoneAfterRead)

- (NSTimer *)timer
{
    return objc_getAssociatedObject(self, @selector(timer));
}

- (void)setTimer:(NSTimer *)timer
{
    objc_setAssociatedObject(self, @selector(timer), timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<IMessageModel>)currentModel
{
    return objc_getAssociatedObject(self, @selector(currentModel));
}

- (void)setCurrentModel:(id<IMessageModel>)currentModel
{
    objc_setAssociatedObject(self, @selector(currentModel), currentModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSRunLoop *)runloop
{
    return objc_getAssociatedObject(self, @selector(runloop));
}

- (void)setRunloop:(NSRunLoop *)runloop
{
    objc_setAssociatedObject(self, @selector(runloop), runloop, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)load
{
    Method backAction = class_getInstanceMethod([self class], @selector(backAction));
    Method FBackAction = class_getInstanceMethod([self class], @selector(FBackAction));
    method_exchangeImplementations(backAction, FBackAction);
}

- (void)FBackAction
{
    [self.navigationController.navigationBar setBarTintColor:RGBACOLOR(30, 167, 252, 1)];
    [self FBackAction];
}
//- (void)FViewDidLoad
//{
////    [self FViewDidLoad];
//
//}

//- (void)handleGoneAfterReadUI:(NSNotification *)notification
//{
//    EMMessage *message = (EMMessage *)notification.object;
//    NSInteger index = [self removeMessageModel:message];
//    if (index >= 0) {
//        
//        [self removeAppointMessage:message index:index];
//    }
//    [self.tableView reloadData];
//}

//获取数据源消息对象indexPath
- (NSInteger)removeMessageModel:(EMMessage *)message
{
    if (![self.conversation.conversationId isEqualToString:message.conversationId])
    {
        return -1;
    }
    __block NSInteger index = -1;
    [self.dataArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj conformsToProtocol:@protocol(IMessageModel)])
        {
            id<IMessageModel> model = (id<IMessageModel>)obj;
            if ([model.messageId isEqualToString:message.messageId])
            {
                index = idx;
                *stop = YES;
            }
        }
    }];
    return index;
}

//删除指定消息
- (void)removeAppointMessage:(EMMessage *)message index:(NSInteger)index
{
    NSIndexSet *indexSet = [[self removeTimePrompt:index] mutableCopy];
    [self.dataArray removeObjectsAtIndexes:indexSet];
    [self.messsagesSource removeObject:message];
}

//数据源移除时间提示
- (NSIndexSet *)removeTimePrompt:(NSInteger)msgIndex
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSetWithIndex:msgIndex];
    if (msgIndex - 1 >= 0 && [[self.dataArray objectAtIndex:msgIndex - 1] isKindOfClass:[NSString class]])
    {
        BOOL isRemoveTimeString = YES;
        if (msgIndex + 1 < self.dataArray.count && ![[self.dataArray objectAtIndex:msgIndex + 1] isKindOfClass:[NSString class]])
        {
            isRemoveTimeString = NO;
        }
        if (isRemoveTimeString)
        {
            [indexSet addIndex:msgIndex - 1];
        }
    }
    return indexSet;
}



//- (BOOL)messageViewController:(EaseMessageViewController *)viewController didSelectMessageModel:(id<IMessageModel>)messageModel
//{
//    BOOL flag = NO;
//    if (!messageModel.isSender && [ChatDemoHelper isGoneAfterReadMessage:messageModel.message]) {
//        [self markReadingMessage:messageModel];
//        switch (messageModel.bodyType) {
//            case EMMessageBodyTypeText:
//            {
//                [self textReadFire];
//                [self showHint:@"消息将在6s后销毁!"];
//                
//            }
//            break;
//                case EMMessageBodyTypeImage:
//            {
//                [[EaseMessageReadManager defaultManager] setReadDelegate:nil];
//                [[EaseMessageReadManager defaultManager] setReadDelegate:self];
//                [[EaseMessageReadManager defaultManager] setImageModel:messageModel];
//            }
//                break;
//                case EMMessageBodyTypeVoice:
//            {
//                [[EaseMessageReadManager defaultManager] setReadDelegate:nil];
//                [[EaseMessageReadManager defaultManager] setReadDelegate:self];
//            }
//                break;
//            default:
//                break;
//        }
//    }
//    
//    return flag;
//}

- (void)markReadingMessage:(id<IMessageModel>)messageModel
{
    self.currentModel = messageModel;
    [[ChatDemoHelper shareHelper] updateCurrentMsg:messageModel.message];
    [self.tableView reloadData];
}

- (void)textReadFire
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:6.0 target:self selector:@selector(timerAction) userInfo:nil repeats:NO];
    if (!self.runloop) {
        
        self.runloop = [[NSRunLoop alloc] init];
    }
    [self.runloop addTimer:self.timer forMode:NSRunLoopCommonModes];
    [self.runloop run];
}

- (void)timerAction
{
    [self handleRemoveAfterReadMessage:self.currentModel];
    self.currentModel = nil;
    if (self.timer.isValid) {
        [self.timer invalidate];
        self.timer = nil;
        self.runloop = nil;
    }
}

- (void)handleRemoveAfterReadMessage:(id<IMessageModel>)model
{
    id<IMessageModel> messageModel = model;
    if (!messageModel) {
        return;
    }
    [[ChatDemoHelper shareHelper] handleGoneAfterReadMessage:model.message];
    
}

- (void)readMessageFinished:(id<IMessageModel>)model
{
    [self handleRemoveAfterReadMessage:model];
}
@end
