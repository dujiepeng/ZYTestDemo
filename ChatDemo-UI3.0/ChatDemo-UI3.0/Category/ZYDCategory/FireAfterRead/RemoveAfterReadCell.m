//
//  RemoveAfterReadCell.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 16/3/10.
//  Copyright © 2016年 WYZ. All rights reserved.
//

#import "RemoveAfterReadCell.h"
#import "EaseBubbleView+Gif.h"
//#import "EMGifImage.h"
#import "UIImageView+HeadImage.h"
#import "ChatDemoHelper+GoneAfterRead.h"

//#import "EaseMob.h"
#import <Hyphenate/Hyphenate.h>

@interface RemoveAfterReadCell()

@property (nonatomic, strong) UIImageView *frontImageView;//上面遮罩
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, assign) int currentCount;

@end

@implementation RemoveAfterReadCell

+ (void)initialize
{
    // UIAppearance Proxy Defaults
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier
                        model:(id<IMessageModel>)model
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier model:model];
    if (self)
    {
        
    }
    return self;
}

- (void)_setupFrontImageViewConstraints
{
    [self.bubbleView addConstraint:[NSLayoutConstraint constraintWithItem:_frontImageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.bubbleView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    
    [self.bubbleView addConstraint:[NSLayoutConstraint constraintWithItem:_frontImageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bubbleView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    
    [self.bubbleView addConstraint:[NSLayoutConstraint constraintWithItem:_frontImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.bubbleView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    
    [self.bubbleView addConstraint:[NSLayoutConstraint constraintWithItem:_frontImageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.bubbleView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    
    [self.bubbleView addConstraint:[NSLayoutConstraint constraintWithItem:_frontImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.bubbleView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    
}

- (void)_setupCountLabelConstraints
{
    [self.bubbleView addConstraint:[NSLayoutConstraint constraintWithItem:_countLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.bubbleView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    [self.bubbleView addConstraint:[NSLayoutConstraint constraintWithItem:_countLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.bubbleView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    [self.bubbleView addConstraint:[NSLayoutConstraint constraintWithItem:_countLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:15]];
    [self.bubbleView addConstraint:[NSLayoutConstraint constraintWithItem:_countLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_countLabel attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
}

- (UIImageView *)frontImageView
{
    if (_frontImageView == nil)
    {
        _frontImageView = [[UIImageView alloc] init];
        _frontImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _frontImageView.backgroundColor = [UIColor clearColor];
        [self.bubbleView addSubview:_frontImageView];
        [self.bubbleView bringSubviewToFront:_frontImageView];
        [self _setupFrontImageViewConstraints];
    }
    return _frontImageView;
}

- (UILabel *)countLabel
{
    if (!_countLabel) {
        _countLabel = [[UILabel alloc] init];
        _countLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _countLabel.backgroundColor = [UIColor clearColor];
        _countLabel.textColor = [UIColor redColor];
        _countLabel.textAlignment = NSTextAlignmentCenter;
        _countLabel.font = [UIFont systemFontOfSize:11];
        [self.bubbleView addSubview:_countLabel];
        [self.bubbleView bringSubviewToFront:_countLabel];
        [self _setupCountLabelConstraints];
    }
    return _countLabel;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.frontImageView.image = self.bubbleView.backgroundImageView.image;
    
}

#pragma mark - IModelCell

- (void)setModel:(id<IMessageModel>)model {
    [super setModel:model];
    self.hasRead.hidden = YES;
    self.frontImageView.hidden = NO;
    self.countLabel.hidden = YES;
    //语音
    if (model.bodyType == EMMessageBodyTypeVoice) {
        CGRect rect = self.bubbleView.frame;
        rect.origin.x = 0;
        rect.origin.y = 0;
        rect.size.width += 10;
        self.frontImageView.frame = rect;
    }
}

/**
 开启定时器
 @param model 消息Model
 */
- (void)startTimer:(id<IMessageModel>)model
{
    NSLog(@"-----定时器开启------%@",model.message.messageId);
    __block int currentIndex = 6;
    self.countLabel.text = @"6";
    dispatch_queue_t fireQueue = dispatch_queue_create("fire", DISPATCH_QUEUE_SERIAL);
    dispatch_source_t fireTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, fireQueue);
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 *NSEC_PER_SEC));
    dispatch_source_set_timer(fireTimer, start, (1.0 * NSEC_PER_SEC), 0);
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(fireTimer, ^{
        
        currentIndex--;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            weakSelf.countLabel.text = [NSString stringWithFormat:@"%d",currentIndex];
        });
        if (currentIndex == 0 && ![[ChatDemoHelper shareHelper] hasGone]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.countLabel.text = @"";
                [[ChatDemoHelper shareHelper] handleGoneAfterReadMessage:model.message];
            });
            
            dispatch_source_cancel(fireTimer);
        }
    });
    dispatch_resume(fireTimer);
}

- (void)isReadMessage:(BOOL)isRead {
    
    if (self.model.bodyType == EMMessageBodyTypeText) {
        
        self.countLabel.hidden = !isRead;
    }
    self.frontImageView.hidden = isRead;
    //发送者本身不加遮罩
    if (self.model.isSender)
    {
        self.frontImageView.hidden = YES;
    }
}

- (BOOL)isCustomBubbleView:(id<IMessageModel>)model
{
    BOOL flag = NO;
    switch (model.bodyType) {
        case EMMessageBodyTypeText:
        {
            if ([model.message.ext objectForKey:@"em_is_big_expression"]) {
                flag = YES;
            }
        }
            break;
        default:
            break;
    }
    return flag;
}

- (void)setCustomModel:(id<IMessageModel>)model
{
    UIImage *image = model.image;
    if (!image) {
        [self.bubbleView.imageView sd_setImageWithURL:[NSURL URLWithString:model.fileURLPath] placeholderImage:[UIImage imageNamed:model.failImageName]];
    } else {
        _bubbleView.imageView.image = image;
    }
    
    if (model.avatarURLPath) {
        [self.avatarView sd_setImageWithURL:[NSURL URLWithString:model.avatarURLPath] placeholderImage:model.avatarImage];
    } else {
        self.avatarView.image = model.avatarImage;
    }
}

- (void)setCustomBubbleView:(id<IMessageModel>)model
{
    if ([model.message.ext objectForKey:@"em_is_big_expression"]) {
        [_bubbleView setupGifBubbleView];
        
        _bubbleView.imageView.image = [UIImage imageNamed:@"imageDownloadFail"];
    }
}

- (void)updateCustomBubbleViewMargin:(UIEdgeInsets)bubbleMargin model:(id<IMessageModel>)model
{
    if ([model.message.ext objectForKey:@"em_is_big_expression"]) {
        [_bubbleView updateGifMargin:bubbleMargin];
    }
}

+ (NSString *)cellIdentifierWithModel:(id<IMessageModel>)model
{
    if ([model.message.ext objectForKey:@"em_is_big_expression"] && [model.message.ext objectForKey:@"goneAfterReadKey"] ) {
        return model.isSender?@"EaseMessageCellSendGif":@"EaseMessageCellRecvGif";
    }
    else {
        return [RemoveAfterReadCell readBurnCellIdentifier:model];
    }
}

+ (CGFloat)cellHeightWithModel:(id<IMessageModel>)model
{
    if ([model.message.ext objectForKey:@"em_is_big_expression"]) {
        return 100;
    } else {
        CGFloat height = [EaseBaseMessageCell cellHeightWithModel:model];
        return height;
    }
}

+ (NSString *)readBurnCellIdentifier:(id<IMessageModel>)model
{
    NSString *cellIdentifier = nil;
    NSString *cellSuffix = @"_BurnAfterRead";
    if (model.isSender) {
        switch (model.bodyType) {
            case EMMessageBodyTypeText:
                cellIdentifier = [EaseMessageCellIdentifierSendText stringByAppendingString:cellSuffix];
                break;
            case EMMessageBodyTypeImage:
                cellIdentifier = [EaseMessageCellIdentifierSendImage stringByAppendingString:cellSuffix];
                break;
            case EMMessageBodyTypeVideo:
                cellIdentifier = [EaseMessageCellIdentifierSendVideo stringByAppendingString:cellSuffix];
                break;
            case EMMessageBodyTypeLocation:
                cellIdentifier = [EaseMessageCellIdentifierSendLocation stringByAppendingString:cellSuffix];
                break;
            case EMMessageBodyTypeVoice:
                cellIdentifier = [EaseMessageCellIdentifierSendVoice stringByAppendingString:cellSuffix];
                break;
            case EMMessageBodyTypeFile:
                cellIdentifier = [EaseMessageCellIdentifierSendFile stringByAppendingString:cellSuffix];
                break;
            default:
                break;
        }
    }
    else{
        switch (model.bodyType) {
            case EMMessageBodyTypeText:
                cellIdentifier = [EaseMessageCellIdentifierRecvText stringByAppendingString:cellSuffix];
                break;
            case EMMessageBodyTypeImage:
                cellIdentifier = [EaseMessageCellIdentifierRecvImage stringByAppendingString:cellSuffix];
                break;
            case EMMessageBodyTypeVideo:
                cellIdentifier = [EaseMessageCellIdentifierRecvVideo stringByAppendingString:cellSuffix];
                break;
            case EMMessageBodyTypeLocation:
                cellIdentifier = [EaseMessageCellIdentifierRecvLocation stringByAppendingString:cellSuffix];
                break;
            case EMMessageBodyTypeVoice:
                cellIdentifier = [EaseMessageCellIdentifierRecvVoice stringByAppendingString:cellSuffix];
                break;
            case EMMessageBodyTypeFile:
                cellIdentifier = [EaseMessageCellIdentifierRecvFile stringByAppendingString:cellSuffix];
                break;
            default:
                break;
        }
    }
    return cellIdentifier;
}


@end
