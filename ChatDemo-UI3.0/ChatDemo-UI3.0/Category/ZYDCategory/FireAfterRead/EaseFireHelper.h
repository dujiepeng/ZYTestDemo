//
//  EaseFireHelper.h
//  ChatDemo-UI3.0
//
//  Created by EaseMob on 2017/3/17.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConversationListController+GoneAfterRead.h"
@interface EaseFireHelper : NSObject

@property (nonatomic) BOOL isGoneAfterReadMode;

@property (nonatomic) BOOL hasGone;

@property (nonatomic, weak) ConversationListController *conversationListVC;

+ (NSDictionary *)structureGoneAfterReadMsgExt:(NSDictionary *)ext;

+ (BOOL)isGoneAfterReadMessage:(EMMessage *)message;

- (void)updateCurrentMsg:(EMMessage *)aMessage;

- (void)handleGoneAfterReadMessage:(EMMessage *)message;

+ (instancetype)sharedHelper;
@end
