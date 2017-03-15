//
//  EaseConversationCell+Top.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 02/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "EaseConversationCell+Top.h"
#import "EaseConversationModel+Top.h"
#import <objc/runtime.h>

@implementation EaseConversationCell (Top)
+ (void)load {
    Method oldMethod = class_getInstanceMethod([EaseConversationCell class], @selector(setModel:));
    Method newMethod = class_getInstanceMethod([EaseConversationCell class], @selector(setZYDModel:));
    method_exchangeImplementations(oldMethod, newMethod);
}

- (void)setZYDModel:(id<IConversationModel>)model {
    [self setZYDModel:model];
    if ([self.model isKindOfClass:[EaseConversationModel class]]) {
        EaseConversationModel *model = (EaseConversationModel *)self.model;
        if (model.isTop) {
            self.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.8];;
        }else {
            self.backgroundColor = [UIColor whiteColor];
        }
    }
}

@end
