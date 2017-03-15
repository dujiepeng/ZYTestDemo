//
//  EaseChatToolbar+InputType.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 09/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "EaseChatToolbar+InputType.h"
#import "ChatViewController+InputType.h"
#import <objc/runtime.h>

@implementation EaseChatToolbar (InputType)
+ (void)load {
    Method old = class_getInstanceMethod([EaseChatToolbar class], @selector(textViewDidChange:));
    Method new = class_getInstanceMethod([EaseChatToolbar class], @selector(ZYDTextViewDidChange:));
    method_exchangeImplementations(old, new);
}

- (void)ZYDTextViewDidChange:(UITextView *)textView {
    [self ZYDTextViewDidChange:textView];
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputTypeChange)]) {
        [self.delegate performSelector:@selector(inputTypeChange) withObject:nil];
    }
}

@end
