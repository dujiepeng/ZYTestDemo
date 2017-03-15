//
//  RedPacketChatViewController+GoneAfterRead.m
//  ChatDemo-UI3.0
//
//  Created by EaseMob on 2017/3/14.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import "RedPacketChatViewController+GoneAfterRead.h"
#import "ChatDemoHelper+GoneAfterRead.h"
#import <objc/runtime.h>
#import "RemoveAfterReadCell.h"
#import "EaseMessageReadManager+GoneAfterRead.h"
#import "UIImage+EMGIF.h"
#import "EaseLocationViewController+GoneAfterRead.h"

@interface RedPacketChatViewController()<EaseMessageReadManagerDelegate, EaseLocationViewControllerDelegate>

@property (nonatomic, strong) id<IMessageModel> currentModel;
@property (nonatomic) BOOL isPlayingAudio;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSRunLoop *runloop;
@end

@implementation RedPacketChatViewController (GoneAfterRead)

#pragma mark - Runtime
- (id<IMessageModel>)currentModel
{
    return objc_getAssociatedObject(self, @selector(currentModel));
}

- (void)setCurrentModel:(id<IMessageModel>)currentModel
{
    objc_setAssociatedObject(self, @selector(currentModel), currentModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isPlayingAudio
{
    return [objc_getAssociatedObject(self, @selector(isPlayingAudio)) boolValue];
}

- (void)setIsPlayingAudio:(BOOL)isPlayingAudio
{
    objc_setAssociatedObject(self, @selector(isPlayingAudio), @(isPlayingAudio), OBJC_ASSOCIATION_ASSIGN);
}

- (NSTimer *)timer
{
    return objc_getAssociatedObject(self, @selector(timer));
}

- (void)setTimer:(NSTimer *)timer
{
    objc_setAssociatedObject(self, @selector(timer), timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    Method viewDidLoad = class_getInstanceMethod([self class], @selector(viewDidLoad));
    Method FViewDidLoad = class_getInstanceMethod([self class], @selector(FViewDidLoad));
    method_exchangeImplementations(viewDidLoad, FViewDidLoad);
    
    Method didSelectMoreView = class_getInstanceMethod([self class], @selector(messageViewController:didSelectMoreView:AtIndex:));
    Method FDidSelectMoreView = class_getInstanceMethod([self class], @selector(FMessageViewController:didSelectMoreView:AtIndex:));
    method_exchangeImplementations(didSelectMoreView, FDidSelectMoreView);
    
    Method cellForMessageModel = class_getInstanceMethod([self class], @selector(messageViewController:cellForMessageModel:));
    Method FCellForMessageModel = class_getInstanceMethod([self class], @selector(FMessageViewController:cellForMessageModel:));
    method_exchangeImplementations(cellForMessageModel, FCellForMessageModel);
    
    Method shouldSendReadAck = class_getInstanceMethod([self class], @selector(messageViewController:shouldSendHasReadAckForMessage:read:));
    Method FShouldSendReadAck = class_getInstanceMethod([self class], @selector(messageViewController:FShouldSendHasReadAckForMessage:read:));
    method_exchangeImplementations(shouldSendReadAck, FShouldSendReadAck);
    
    Method messageCellSelect = class_getInstanceMethod([self class], @selector(messageCellSelected:));
    Method FMessageCellSelect = class_getInstanceMethod([self class], @selector(FMessageCellSelected:));
    method_exchangeImplementations(messageCellSelect, FMessageCellSelect);
    
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"handleGoneAfterReadUI" object:nil];
    [[ChatDemoHelper shareHelper] setIsGoneAfterReadMode:NO];
}

#pragma mark - 消息点击
- (void)FMessageCellSelected:(id<IMessageModel>)model
{
    if (model.bodyType == EMMessageBodyTypeVoice && [ChatDemoHelper isGoneAfterReadMessage:model.message]) {
    
        self.scrollToBottomWhenAppear = NO;
        EMVoiceMessageBody *body = (EMVoiceMessageBody *)model.message.body;
        EMDownloadStatus downloadStatus = [body downloadStatus];
        if (downloadStatus == EMDownloadStatusDownloading) {
            [self showHint:NSEaseLocalizedString(@"message.downloadingAudio", @"downloading voice, click later")];
            return;
        }
        else if (downloadStatus == EMDownloadStatusFailed)
        {
            [self showHint:NSEaseLocalizedString(@"message.downloadingAudio", @"downloading voice, click later")];
            [[EMClient sharedClient].chatManager downloadMessageAttachment:model.message progress:nil completion:nil];
            return;
        }
        __weak RedPacketChatViewController *weakSelf = self;
        BOOL isPrepare = [[EaseMessageReadManager defaultManager] prepareMessageAudioModel:model updateViewCompletion:^(EaseMessageModel *prevAudioModel, EaseMessageModel *currentAudioModel) {
            if (prevAudioModel || currentAudioModel) {
                [weakSelf.tableView reloadData];
            }
        }];
        if (isPrepare) {
            self.isPlayingAudio = YES;
            [self markReadingMessage:model];
            __weak RedPacketChatViewController *weakSelf = self;
            [[EMCDDeviceManager sharedInstance] enableProximitySensor];
            [[EMCDDeviceManager sharedInstance] asyncPlayingWithPath:model.fileLocalPath completion:^(NSError *error) {
                [[EaseMessageReadManager defaultManager] stopMessageAudioModel];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.tableView reloadData];
                    weakSelf.isPlayingAudio = NO;
                    [[EMCDDeviceManager sharedInstance] disableProximitySensor];
                    [weakSelf readMessageFinished:model];
                });
            }];
        }
        else{
            [self readMessageFinished:model];
            self.isPlayingAudio = NO;
        }
        return;
    }

    if (model.bodyType == EMMessageBodyTypeVideo && [ChatDemoHelper isGoneAfterReadMessage:model.message]) {
        self.currentModel = model;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    }
    if (model.bodyType == EMMessageBodyTypeLocation && [ChatDemoHelper isGoneAfterReadMessage:model.message]) {
#warning 阅后即焚 - 位置需要补充
        EaseLocationViewController *locationController = [[EaseLocationViewController alloc] initWithLocation:CLLocationCoordinate2DMake(model.latitude, model.longitude)];
        locationController.locationModel = model;
        locationController.locDelegate = self;
        [self.navigationController pushViewController:locationController animated:YES];
        return;
    }
    [self FMessageCellSelected:model];
}

// 视频播放完成
- (void)moviePlayFinished:(NSNotification *)notification
{
    [self readMessageFinished:self.currentModel];
    self.currentModel = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}

- (void)locationMessageReadAck:(id<IMessageModel>)model
{
    [self readMessageFinished:model];
    
}


- (void)FViewDidLoad {
    
    [self FViewDidLoad];
    [[ChatDemoHelper shareHelper] setIsGoneAfterReadMode:NO];
    if (self.conversation.type == EMConversationTypeChat) {
       
        [self.chatBarMoreView insertItemWithImage:[UIImage imageNamed:@"timg.jpeg"] highlightedImage:[UIImage imageNamed:@"timg.jpeg"]  title:@"阅后即焚"];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGoneAfterReadUI:) name:@"handleGoneAfterReadUI" object:nil];

}
#pragma mark - 阅后即焚UI更新
- (void)handleGoneAfterReadUI:(NSNotification *)notification
{
    EMMessage *message = (EMMessage *)notification.object;
    NSInteger index = [self removeMessageModel:message];
    id <IMessageModel>model = [[EaseMessageModel alloc] initWithMessage:message];
    if ([self.dataArray[index] conformsToProtocol:@protocol(IMessageModel)]) {
        model = self.dataArray[index];
    }
    if (index >= 0) {
        [self removeAppointMessage:model.message index:index];
    }
    [self.tableView reloadData];
}

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

#pragma mark - 开启阅后即焚
- (void)FMessageViewController:(EaseMessageViewController *)viewController didSelectMoreView:(EaseChatBarMoreView *)moreView AtIndex:(NSInteger)index
{
    if (index == 7) {
        
        NSLog(@"-------阅后即焚");
        [self changeGoneAfterReadMode];
    } else {
        
        [self FMessageViewController:viewController didSelectMoreView:moreView AtIndex:index];
    }
}

/**
 *  开启阅后即焚
 */
- (void)changeGoneAfterReadMode
{
    if (![[ChatDemoHelper shareHelper] isGoneAfterReadMode])
    {
        
        if ([self.navigationController.navigationBar respondsToSelector:@selector(setBarTintColor:)]) {
            
            [self.navigationController.navigationBar setBarTintColor:[UIColor redColor]];
        }
        [[ChatDemoHelper shareHelper] setIsGoneAfterReadMode:YES];
    } else {
        
        if ([self.navigationController.navigationBar respondsToSelector:@selector(setBarTintColor:)]) {
            
            [self.navigationController.navigationBar setBarTintColor:RGBACOLOR(30, 167, 252, 1)];
        }
        [[ChatDemoHelper shareHelper] setIsGoneAfterReadMode:NO];
    }
    [self.chatToolbar endEditing:YES];
}

- (UITableViewCell *)FMessageViewController:(UITableView *)tableView cellForMessageModel:(id<IMessageModel>)messageModel
{
    if ([ChatDemoHelper isGoneAfterReadMessage:messageModel.message]) {
        
        NSString *cellIdentifier = [RemoveAfterReadCell cellIdentifierWithModel:messageModel];
        RemoveAfterReadCell *cell = (RemoveAfterReadCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            
            cell = [[RemoveAfterReadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier model:messageModel];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if ([cell isCustomBubbleView:messageModel]) {
            
            EaseEmotion *emotion = [super emotionURLFormessageViewController:self messageModel:messageModel];
            if (emotion) {
                
                messageModel.image = [UIImage sd_animatedGIFNamed:emotion.emotionOriginal];
                messageModel.fileURLPath = emotion.emotionOriginalURL;
            }
        }
        cell.model = messageModel;
        BOOL isReading = self.currentModel && [self.currentModel.messageId isEqualToString:messageModel.messageId];
        [cell isReadMessage:isReading];
        return cell;
    }
    return [self FMessageViewController:tableView cellForMessageModel:messageModel];
}

/**
 *  是否发送已读回执，阅后即焚消息不发已读回执
 */
- (BOOL)messageViewController:(EaseMessageViewController *)viewController FShouldSendHasReadAckForMessage:(EMMessage *)message read:(BOOL)read
{
    if ([ChatDemoHelper isGoneAfterReadMessage:message]) {
        return NO;
    }
    return [self messageViewController:viewController FShouldSendHasReadAckForMessage:message read:read];
}

- (BOOL)messageViewController:(EaseMessageViewController *)viewController didSelectMessageModel:(id<IMessageModel>)messageModel
{
    BOOL flag = NO;
    if (!messageModel.isSender && [ChatDemoHelper isGoneAfterReadMessage:messageModel.message]) {
        [self markReadingMessage:messageModel];
        switch (messageModel.bodyType) {
            case EMMessageBodyTypeText:
            {
                [self textReadFire];
                [self showHint:@"消息将在6s后销毁!"];
                
            }
                break;
            case EMMessageBodyTypeImage:
            {
                [[EaseMessageReadManager defaultManager] setReadDelegate:nil];
                [[EaseMessageReadManager defaultManager] setReadDelegate:self];
                [[EaseMessageReadManager defaultManager] setImageModel:messageModel];
            }
                break;
            default:
                break;
        }
    }
    
    return flag;
}

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
