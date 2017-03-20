//
//  EaseConversationCell+GroupPushBlock.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/3/17.
//  Copyright © 2017年 WYZ. All rights reserved.
//

#import "EaseConversationCell+GroupPushBlock.h"
#import <objc/runtime.h>

@implementation EaseImageView (GroupPushBlock)

+ (void)load {
    Method oldBadgeMethod = class_getInstanceMethod([EaseImageView class], @selector(setBadge:));
    Method newBadgeMethod = class_getInstanceMethod([EaseImageView class], @selector(GPBSetBadge:));
    method_exchangeImplementations(oldBadgeMethod, newBadgeMethod);
}

- (void)GPBSetBadge:(NSInteger)badge {
    [self GPBSetBadge:badge];
    UILabel *badgeView = [self valueForKey:@"badgeView"];
    if (badge == NSNotFound && self.showBadge) {
        badgeView.text = @"";
        badgeView.layer.cornerRadius = 5.0f;
        
        NSLayoutConstraint *badgeWidthConstraint = [self valueForKey:@"badgeWidthConstraint"];
        [self removeConstraint:badgeWidthConstraint];
        badgeWidthConstraint = [NSLayoutConstraint constraintWithItem:badgeView
                                                            attribute:NSLayoutAttributeWidth
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:nil
                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                           multiplier:0
                                                             constant:10.f];
        [self addConstraint:badgeWidthConstraint];
        [self setValue:badgeWidthConstraint forKey:@"badgeWidthConstraint"];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:badgeView
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:badgeView
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:1.0
                                                          constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:badgeView
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.imageView
                                                         attribute:NSLayoutAttributeRight
                                                        multiplier:1.0
                                                          constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:badgeView
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.imageView
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0
                                                          constant:0]];
    }
    else {
        badgeView.layer.cornerRadius = self.badgeSize / 2;
        NSLayoutConstraint *badgeWidthConstraint = [self valueForKey:@"badgeWidthConstraint"];
        [self removeConstraint:badgeWidthConstraint];
        [self performSelector:@selector(_setupBadgeViewConstraint) withObject:nil];
    }
    [self setValue:badgeView forKey:@"badgeView"];
    
    
}

@end

@implementation EaseConversationCell (GroupPushBlock)

+ (void)load {
    Method oldModelMethod = class_getInstanceMethod([EaseConversationCell class], @selector(setModel:));
    Method newModelMethod = class_getInstanceMethod([EaseConversationCell class], @selector(GPBSetModel:));
    method_exchangeImplementations(oldModelMethod, newModelMethod);
}

- (void)GPBSetModel:(id<IConversationModel>)model {
    [self GPBSetModel:model];
    NSArray *blockGroups = [[EMClient sharedClient].groupManager getGroupsWithoutPushNotification:nil];
    if ([blockGroups containsObject:model.conversation.conversationId] &&
        model.conversation.type == EMConversationTypeGroupChat && model.conversation.unreadMessagesCount > 0) {
        self.avatarView.badge = NSNotFound;
    }
}

@end
