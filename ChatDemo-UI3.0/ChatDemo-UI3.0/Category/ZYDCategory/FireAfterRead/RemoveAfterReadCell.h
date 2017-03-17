//
//  RemoveAfterReadCell.h
//  ChatDemo-UI3.0
//
//  Created by WYZ on 16/3/10.
//  Copyright © 2016年 WYZ. All rights reserved.
//

#import "EaseCustomMessageCell.h"

@interface RemoveAfterReadCell :EaseCustomMessageCell
@property (nonatomic) BOOL beenRead;

- (void)isReadMessage:(BOOL)isRead;
- (BOOL)isCustomBubbleView:(id<IMessageModel>)model;
- (void)startTimer:(id<IMessageModel>)model;


@end
