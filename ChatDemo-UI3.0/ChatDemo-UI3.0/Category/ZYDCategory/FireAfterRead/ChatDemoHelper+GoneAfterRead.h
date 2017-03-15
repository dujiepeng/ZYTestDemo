//
//  ChatDemoHelper+GoneAfterRead.h
//  ChatDemo-UI3.0
//
//  Created by EaseMob on 2017/3/14.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import "ChatDemoHelper.h"

@interface ChatDemoHelper (GoneAfterRead)

@property (nonatomic) BOOL isGoneAfterReadMode;

+ (NSDictionary *)structureGoneAfterReadMsgExt:(NSDictionary *)ext;

+ (BOOL)isGoneAfterReadMessage:(EMMessage *)message;

- (void)updateCurrentMsg:(EMMessage *)aMessage;

- (void)handleGoneAfterReadMessage:(EMMessage *)message;

@end
