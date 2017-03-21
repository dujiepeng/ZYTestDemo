//
//  EaseImageView+GroupPushBlock.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/3/21.
//  Copyright © 2017年 WYZ. All rights reserved.
//

#import "EaseImageView+GroupPushBlock.h"
#import <objc/runtime.h>

#define REDPOINT_DIAMETER    10.0f

static char redPointKey;

@interface EaseImageView()

@property (nonatomic, strong) UIView *redPointView;

@end

@implementation EaseImageView (GroupPushBlock)

+ (void)load {
    
    Method oldSubViewMethod = class_getInstanceMethod([EaseImageView class], @selector(_setupSubviews));
    Method newSubViewMethod = class_getInstanceMethod([EaseImageView class], @selector(_GPBSetupSubviews));
    method_exchangeImplementations(oldSubViewMethod, newSubViewMethod);
    
    Method oldBadgeMethod = class_getInstanceMethod([EaseImageView class], @selector(setBadge:));
    Method newBadgeMethod = class_getInstanceMethod([EaseImageView class], @selector(GPBSetBadge:));
    method_exchangeImplementations(oldBadgeMethod, newBadgeMethod);
}

#pragma mark - getter
- (UIView *)redPointView {
    return objc_getAssociatedObject(self, &redPointKey);
}

#pragma mark - setter
- (void)setRedPointView:(UIView *)redPointView {
    objc_setAssociatedObject(self, &redPointKey, redPointView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)_GPBSetupSubviews {
    [self _GPBSetupSubviews];
    if (!self.redPointView) {
        self.redPointView = [[UIView alloc] init];
        self.redPointView.translatesAutoresizingMaskIntoConstraints = NO;
        self.redPointView.backgroundColor = [UIColor redColor];
        self.redPointView.hidden = YES;
        self.redPointView.layer.cornerRadius = REDPOINT_DIAMETER / 2.0;
        self.redPointView.clipsToBounds = YES;
        [self addSubview:self.redPointView];
        
        [self _setupRedPointViewConstraint];
    }
    
}

- (void)_setupRedPointViewConstraint {
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.redPointView
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:0
                                                      constant:REDPOINT_DIAMETER]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.redPointView
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1.0
                                                      constant:REDPOINT_DIAMETER]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.redPointView
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.imageView
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1.0
                                                      constant:0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.redPointView
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.imageView
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1.0
                                                      constant:0]];
}


- (void)GPBSetBadge:(NSInteger)badge {
    [self GPBSetBadge:badge];
    UILabel *badgeView = [self valueForKey:@"badgeView"];
    if (badge == NSNotFound && self.showBadge) {
        self.redPointView.hidden = NO;
        badgeView.hidden = YES;
    }
    else {
        self.redPointView.hidden = YES;
        badgeView.hidden = !self.showBadge;
    }
    [self setValue:badgeView forKey:@"badgeView"];
    
    
}

@end
