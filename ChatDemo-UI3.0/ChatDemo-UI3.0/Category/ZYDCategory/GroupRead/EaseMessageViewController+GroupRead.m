//
//  EaseMessageViewController+GroupRead.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/3/9.
//  Copyright © 2017年 WYZ. All rights reserved.
//

#import "EaseMessageViewController+GroupRead.h"
#import <objc/runtime.h>
#import "LocalDataTools.h"
#import "EaseBaseMessageCell+GroupRead.h"
#import "GroupMessageReadersViewController.h"
#import "DefineKey.h"

static char timerKey;
static char readMsgIdInfoKey;
static char queueKey;

@interface EaseMessageViewController()

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) NSMutableDictionary *readMsgIdDic; //key:toUser value:@[msgId1,msgId2]

@property (nonatomic, strong) dispatch_queue_t cmdHandleQueue;

@end

@implementation EaseMessageViewController (GroupRead)

+ (void)load {
    
    Method oldReadMethod = class_getInstanceMethod([EaseMessageViewController class], @selector(_sendHasReadResponseForMessages:isRead:));
    Method newReadMethod = class_getInstanceMethod([EaseMessageViewController class], @selector(ZYDSendHasReadResponseForMessages:isRead:));
    method_exchangeImplementations(oldReadMethod, newReadMethod);
    
    Method oldShouldReadMethod = class_getInstanceMethod([EaseMessageViewController class], @selector(shouldSendHasReadAckForMessage:read:));
    Method newShouldReadMethod = class_getInstanceMethod([EaseMessageViewController class], @selector(ZYDShouldSendHasReadAckForMessage:read:));
    method_exchangeImplementations(oldShouldReadMethod, newShouldReadMethod);
    
    Method oldLoadMethod = class_getInstanceMethod([EaseMessageViewController class], @selector(viewDidLoad));
    Method newLoadMethod = class_getInstanceMethod([EaseMessageViewController class], @selector(groupReadViewDidLoad));
    method_exchangeImplementations(oldLoadMethod, newLoadMethod);
    
}

- (void)groupReadViewDidLoad {
    
    if (self.conversation.type == EMConversationTypeGroupChat) {
        [[LocalDataTools tools] getLocalGroupReadItemsFromPlist:self.conversation.conversationId];
    }
    [self groupReadViewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateGroupMessageReadCount:)
                                                 name:UPDATE_GROUPMSG_READCOUNT
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(entryGroupMessageReadersList:)
                                                 name:ENTRY_GROUPMSG_READERLIST
                                               object:nil];
}

- (BOOL)ZYDShouldSendHasReadAckForMessage:(EMMessage *)message
                                  read:(BOOL)read
{
    NSString *account = [[EMClient sharedClient] currentUsername];
    
    if (message.chatType == EMChatTypeChatRoom || message.isReadAcked || [account isEqualToString:message.from] || ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) || !self.isViewDidAppear)
    {
        return NO;
    }
    
    EMMessageBody *body = message.body;
    if (((body.type == EMMessageBodyTypeVideo) ||
         (body.type == EMMessageBodyTypeVoice) ||
         (body.type == EMMessageBodyTypeImage)) &&
        !read)
    {
        return NO;
    }
    else
    {
        if (message.chatType == EMChatTypeGroupChat) {
            message.isReadAcked = YES;
            [[EMClient sharedClient].chatManager updateMessage:message completion:^(EMMessage *aMessage, EMError *aError) {
                if (!aError) {
//                    NSLog(@"更新成功");
                }
            }];
        }
        return YES;
    }
}


- (void)ZYDSendHasReadResponseForMessages:(NSArray*)messages isRead:(BOOL)isRead {
    NSMutableArray *unreadMessages = [NSMutableArray array];
    if (!self.readMsgIdDic) {
        self.readMsgIdDic = [NSMutableDictionary dictionary];
    }
    for (NSInteger i = 0; i < [messages count]; i++)
    {
        EMMessage *message = messages[i];
        BOOL isSend = YES;
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(messageViewController:shouldSendHasReadAckForMessage:read:)]) {
            isSend = [self.dataSource messageViewController:self
                         shouldSendHasReadAckForMessage:message read:isRead];
        }
        else{
            isSend = [self shouldSendHasReadAckForMessage:message
                                                     read:isRead];
        }
        
        if (isSend)
        {
            [unreadMessages addObject:message];
            if (message.chatType == EMChatTypeGroupChat) {
                NSString *toUser = message.from;
                NSMutableArray *msgIds = [NSMutableArray arrayWithArray:self.readMsgIdDic[toUser]];
                [msgIds addObject:message.messageId];
                [self.readMsgIdDic setObject:msgIds forKey:toUser];
            }
        }
    }
    
    if ([unreadMessages count])
    {
        for (EMMessage *message in unreadMessages)
        {
            [[EMClient sharedClient].chatManager sendMessageReadAck:message completion:nil];
        }
    }
    if (!self.cmdHandleQueue) {
        [self startTimerRunLoop];
    }
}


/*
 * 发送群组消息已读状态
 */
- (void)sendGroupReadCmd:(NSArray *)msgIds
                  toUser:(NSString *)toUser
{
    if (msgIds.count == 0 || toUser.length == 0) {
        return;
    }
    
    EMCmdMessageBody *_body = [[EMCmdMessageBody alloc] initWithAction:GROUP_READ_CMD];
    NSString *_currentUsername = [EMClient sharedClient].currentUsername;
    NSDictionary *_ext = @{UPDATE_MSGID_LIST:msgIds, CURRENT_CONVERSATIONID:self.conversation.conversationId};
    EMMessage *_message = [[EMMessage alloc] initWithConversationID:toUser
                                                              from:_currentUsername
                                                                to:toUser
                                                              body:_body
                                                                ext:_ext];
    _message.chatType = EMChatTypeChat;
    [[EMClient sharedClient].chatManager sendMessage:_message
                                            progress:nil
                                          completion:^(EMMessage *message, EMError *error) {
                                              if (!error) {
                                                  NSLog(@"发送成功");
                                              }
                                              else {
                                                  [self showHint:@"发送失败"];
                                                  NSLog(@"保存数据失败: 群组id：%@ 消息id：%@  消息发送方：%@", self.conversation.conversationId,msgIds,toUser);
                                              }
                                          }
     ];
}

#pragma mark - Notification Method

- (void)updateGroupMessageReadCount:(NSNotification *)nof {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        if ([nof.object isKindOfClass:[NSArray class]]) {
            NSMutableArray *msgIds = [NSMutableArray arrayWithArray:(NSArray *)nof.object];
            __block NSMutableArray *indexPaths = [NSMutableArray array];
            [self.dataArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj conformsToProtocol:@protocol(IMessageModel)]) {
                    EaseMessageModel *model = (EaseMessageModel *)obj;
                    NSString *messageId = model.message.messageId;
                    if ([msgIds containsObject:messageId]) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
                        [indexPaths addObject:indexPath];
                        [msgIds removeObject:messageId];
                        if (msgIds.count <= 0) {
                            *stop = YES;
                        }
                    }
                }
            }];
            if (indexPaths.count > 0) {
                dispatch_async(dispatch_get_main_queue(), ^(){
                    [weakSelf.tableView beginUpdates];
                    [weakSelf.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                    [weakSelf.tableView endUpdates];
                });
            }
        }
    });
    
}

- (void)entryGroupMessageReadersList:(NSNotification *)nof {
    if ([nof.object isKindOfClass:[NSArray class]]) {
        NSArray *readers = (NSArray *)nof.object;
        if (readers.count > 0) {
            
            GroupMessageReadersViewController *vc = [[GroupMessageReadersViewController alloc] init];
            vc.dataArray = [readers copy];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}



#pragma mark - getter

- (NSTimer *)timer
{
    return objc_getAssociatedObject(self, &timerKey);
}

- (NSMutableDictionary *)readMsgIdDic {
    return objc_getAssociatedObject(self, &readMsgIdInfoKey);
}

- (dispatch_queue_t)cmdHandleQueue {
    return objc_getAssociatedObject(self, &queueKey);
}

#pragma mark - setter

- (void)setTimer:(NSTimer *)timer
{
    objc_setAssociatedObject(self, &timerKey, timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setReadMsgIdDic:(NSMutableDictionary *)readMsgIdDic {
    objc_setAssociatedObject(self, &readMsgIdInfoKey, readMsgIdDic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setCmdHandleQueue:(dispatch_queue_t)cmdHandleQueue {
    objc_setAssociatedObject(self, &queueKey, cmdHandleQueue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//接收方，启动runloop
- (void)startTimerRunLoop
{
    if (self.cmdHandleQueue && self.timer) {
        return;
    }
    
    self.cmdHandleQueue = dispatch_queue_create("sendCmdMessage", DISPATCH_QUEUE_SERIAL);
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.cmdHandleQueue, ^{
        __strong typeof(EaseMessageViewController) *strongSelf = weakSelf;
        if (!strongSelf.timer)
        {
            strongSelf.timer = [NSTimer scheduledTimerWithTimeInterval:READ_CMD_TIMEINTERVAL target:self selector:@selector(handleTimerAction1:) userInfo:nil repeats:NO];
        }
        [[NSRunLoop currentRunLoop] addTimer:strongSelf.timer forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] run];
    });
}

//关闭runloop
- (void)stopRunLoop
{
    if (self.timer.isValid)
    {
        [self.timer invalidate];
        self.timer = nil;
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
        self.cmdHandleQueue = nil;
    }
}

//定时处理方法
- (void)handleTimerAction1:(NSTimer *)timer
{
    NSDictionary *cacheDic = [self.readMsgIdDic copy];
    [self.readMsgIdDic removeAllObjects];
    for (NSString *toUser in cacheDic) {
        NSArray *msgIds = cacheDic[toUser];
        [self sendGroupReadCmd:msgIds toUser:toUser];
    }
    [self stopRunLoop];
    
}


@end
