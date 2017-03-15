//
//  EaseBaseMessageCell+GroupRead.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/3/10.
//  Copyright © 2017年 WYZ. All rights reserved.
//

#import "EaseBaseMessageCell+GroupRead.h"
#import <objc/runtime.h>
#import "LocalDataTools.h"
#import "EMGroupReadControl.h"

static char hasReadControlKey;

@interface EaseBaseMessageCell()

@property (nonatomic, strong) EMGroupReadControl *hasReadControl;

@end

@implementation EaseBaseMessageCell (GroupRead)

+ (void)load {
    Method oldReadMethod = class_getInstanceMethod([EaseBaseMessageCell class], @selector(initWithStyle:reuseIdentifier:model:));
    Method newReadMethod = class_getInstanceMethod([EaseBaseMessageCell class], @selector(ZYDInitWithStyle:reuseIdentifier:model:));
    method_exchangeImplementations(oldReadMethod, newReadMethod);
    
    Method oldSetModelMethod = class_getInstanceMethod([EaseBaseMessageCell class], @selector(setModel:));
    Method newSetModelMethod = class_getInstanceMethod([EaseBaseMessageCell class], @selector(ZYDSetModel:));
    method_exchangeImplementations(oldSetModelMethod, newSetModelMethod);
}

- (void)setHasReadControl:(EMGroupReadControl *)hasReadControl {
    objc_setAssociatedObject(self, &hasReadControlKey, hasReadControl, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (EMGroupReadControl *)hasReadControl {
    return objc_getAssociatedObject(self, &hasReadControlKey);
}


- (instancetype)ZYDInitWithStyle:(UITableViewCellStyle)style
                 reuseIdentifier:(NSString *)reuseIdentifier
                           model:(id<IMessageModel>)model {
    [self ZYDInitWithStyle:style reuseIdentifier:reuseIdentifier model:model];
    
    if (model.isSender && model.message.chatType == EMChatTypeGroupChat) {
        self.hasReadControl = [[[NSBundle mainBundle] loadNibNamed:@"EMGroupReadControl" owner:self options:nil] lastObject];
        self.hasReadControl.accessibilityIdentifier = @"has_read_count";
        self.hasReadControl.translatesAutoresizingMaskIntoConstraints = NO;
        self.hasReadControl.hidden = YES;
        [self.hasReadControl sizeToFit];
        [self.contentView addSubview:self.hasReadControl];
        
        NSLayoutConstraint *constraintWidth = [NSLayoutConstraint constraintWithItem:self.hasReadControl attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0 constant:40];
        
        NSLayoutConstraint *constraintHeight = [NSLayoutConstraint constraintWithItem:self.hasReadControl attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0 constant:44];
        
        NSLayoutConstraint *constraintRight = [NSLayoutConstraint constraintWithItem:self.hasReadControl attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.bubbleView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-5];
        
        NSLayoutConstraint *constraintBottom = [NSLayoutConstraint constraintWithItem:self.hasReadControl attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bubbleView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
        
        [self addConstraint:constraintWidth];
        [self addConstraint:constraintHeight];
        [self addConstraint:constraintBottom];
        [self addConstraint:constraintRight];
    }
    return self;
}

- (void)ZYDSetModel:(id<IMessageModel>)model {
    [self ZYDSetModel:model];
    self.hasReadControl.hidden = YES;
    if ([LocalDataTools tools].groupReadItems[model.messageId]) {
        NSArray *readerNames = [LocalDataTools tools].groupReadItems[model.messageId];
        if (readerNames.count > 0) {
            self.hasReadControl.hidden = NO;
            [self.hasReadControl setReaders:readerNames];
        }
    }
}

@end
