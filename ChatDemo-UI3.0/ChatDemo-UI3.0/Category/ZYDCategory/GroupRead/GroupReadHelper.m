//
//  GroupReadHelper.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/3/20.
//  Copyright © 2017年 WYZ. All rights reserved.
//

#import "GroupReadHelper.h"
#import "DefineKey.h"
#import "LocalDataTools.h"

static GroupReadHelper *_helper = nil;

@interface GroupReadHelper()<EMChatManagerDelegate>

@end

@implementation GroupReadHelper

+ (GroupReadHelper *)helper {
    static dispatch_once_t once;
    dispatch_once(&once, ^(){
        _helper = [[GroupReadHelper alloc] init];
    });
    return _helper;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[EMClient sharedClient].chatManager addDelegate:self delegateQueue:nil];
    }
    return self;
}

- (void)dealloc {
    [[EMClient sharedClient].chatManager removeDelegate:self];
}

#pragma mark - EMChatManagerDelegate

- (void)cmdMessagesDidReceive:(NSArray *)aCmdMessages {
    for (EMMessage *msg in aCmdMessages) {
        if (msg.body.type == EMMessageBodyTypeCmd) {
            EMCmdMessageBody *body = (EMCmdMessageBody *)msg.body;
            if ([body.action isEqualToString:GROUP_READ_ACTION]) {
                //群组消息已读
                NSDictionary *ext = msg.ext;
                NSString *groupId = ext[GROUP_READ_CONVERSATION_ID];
                NSArray *msgIds = ext[GROUP_READ_MSG_ID_ARRAY];
                NSString *readerName = msg.from;
                [[LocalDataTools tools] addDataToPlist:groupId msgIds:msgIds readerName:readerName];
            }
        }
    }
}

@end
