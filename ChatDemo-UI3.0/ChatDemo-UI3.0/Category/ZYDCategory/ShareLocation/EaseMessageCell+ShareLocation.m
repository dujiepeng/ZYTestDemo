//
//  EaseMessageCell+ShareLocation.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 09/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "EaseMessageCell+ShareLocation.h"
#import "EaseMessageViewController+ShareLocation.h"
#import "DefineKey.h"
#import <objc/runtime.h>

@implementation EaseMessageCell (ShareLocation)

+(void)load {
    Method oldMethod = class_getInstanceMethod([EaseMessageCell class], @selector(bubbleViewTapAction:));
    Method newMethod = class_getInstanceMethod([EaseMessageCell class], @selector(ZYDBubbleViewTapAction:));
    method_exchangeImplementations(oldMethod, newMethod);
}
#pragma mark - action

/*!
 @method
 @brief 气泡的点击手势事件
 @discussion
 @result
 */
- (void)ZYDBubbleViewTapAction:(UITapGestureRecognizer *)tapRecognizer
{
    if (tapRecognizer.state == UIGestureRecognizerStateEnded) {
        if (self.model.message.body.type == EMMessageBodyTypeText) {
            if ([self.delegate respondsToSelector:@selector(shareLocationMessageHasPassed)]) {
                if ([self.model.message.ext[SHARE_LOCATION_MESSAGE_FLAG] boolValue]) {
                    [self.delegate performSelector:@selector(shareLocationMessageHasPassed) withObject:nil];
                    return;
                }
            }
        }
    }
    
    [self ZYDBubbleViewTapAction:tapRecognizer];
}

@end
