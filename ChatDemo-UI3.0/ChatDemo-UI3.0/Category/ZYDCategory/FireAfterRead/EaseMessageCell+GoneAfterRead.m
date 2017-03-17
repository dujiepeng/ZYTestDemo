//
//  EaseMessageCell+GoneAfterRead.m
//  ChatDemo-UI3.0
//
//  Created by EaseMob on 2017/3/15.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import "EaseMessageCell+GoneAfterRead.h"
#import <objc/runtime.h>
#import "RemoveAfterReadCell.h"
#import "ChatDemoHelper+GoneAfterRead.h"
@implementation EaseMessageCell (GoneAfterRead)

+ (void)load
{
    Method bubbleViewTapAction = class_getInstanceMethod([self class], @selector(bubbleViewTapAction:));
    Method FBubbleViewTapAction = class_getInstanceMethod([self class], @selector(FBubbleViewTapAction:));
    method_exchangeImplementations(bubbleViewTapAction, FBubbleViewTapAction);
}

- (void)FBubbleViewTapAction:(UITapGestureRecognizer *)tapRecognizer
{
    [self FBubbleViewTapAction:tapRecognizer];
    if (self.model.bodyType == EMMessageBodyTypeText) {
        
        RemoveAfterReadCell *cell = (RemoveAfterReadCell *)self;
        // 点击bubble 隐藏遮罩
        [cell isReadMessage:YES];
        [cell startTimer:self.model];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(messageCellSelected:)]) {
            
            [self.delegate messageCellSelected:self.model];
        }
    }
}

@end
