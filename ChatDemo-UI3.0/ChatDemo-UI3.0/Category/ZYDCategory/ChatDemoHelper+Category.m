//
//  ChatDemoHelper+Category.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 27/02/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "ChatDemoHelper+Category.h"
#import "ShareLocationAnnotation.h"
#import "EMConversation+Draft.h"
#import <Hyphenate/Hyphenate.h>
#import "EaseMessageViewController+GroupRead.h"
#import "LocalDataTools.h"
#import <objc/runtime.h>

#import "DefineKey.h"
#import "LocalDataTools.h"

@implementation ChatDemoHelper (Category)
+ (void)load {
    Method oldUpdataMessagesMethod = class_getInstanceMethod([ChatDemoHelper class], @selector(didReceiveMessages:));
    Method newUpdataMessagesMethod = class_getInstanceMethod([ChatDemoHelper class], @selector(ZYDDidReceiveMessages:));
    method_exchangeImplementations(oldUpdataMessagesMethod, newUpdataMessagesMethod);
    
    Method oldConversationListCallbackMethod = class_getInstanceMethod([ChatDemoHelper class], @selector(didUpdateConversationList:));
    Method newConversationListCallbackMethod = class_getInstanceMethod([ChatDemoHelper class], @selector(ZYDDidUpdateConversationList:));
    method_exchangeImplementations(oldConversationListCallbackMethod, newConversationListCallbackMethod);
}

- (void)ZYDDidReceiveMessages:(NSArray *)aMessages{
    NSMutableArray *msgAry = [[NSMutableArray alloc] init];
    NSMutableArray *noticeAry = [[NSMutableArray alloc] init];
    for (EMMessage *msg in aMessages) {
        if ([msg.from isEqualToString:@"admin"] && msg.chatType == EMChatTypeChat) {
            [noticeAry addObject:msg];
        }else {
            [msgAry addObject:msg];
        }
    }
    
    if (noticeAry.count > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"haveReceiveNotices" object:noticeAry];
    }
    
    if (msgAry.count > 0) {
        [self ZYDDidReceiveMessages:msgAry];
    }
}

- (void)cmdMessagesDidReceive:(NSArray *)aCmdMessages {
    NSMutableSet *set = [[NSMutableSet alloc] init];
    for (EMMessage *msg in aCmdMessages) {
        if (msg.body.type == EMMessageBodyTypeCmd) {
            EMCmdMessageBody *body = (EMCmdMessageBody *)msg.body;
            if ([body.action isEqualToString:@"shareLocation"]) {
                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                if (![msg.ext[ISSTOP] boolValue]) {
                    dic[@"lan"] = msg.ext[LATITUDE];
                    dic[@"lon"] = msg.ext[LONGITUDE];
                }else {
                    dic[@"isStop"] = msg.ext[ISSTOP];
                }
                dic[@"username"] = msg.from;
                [set addObject:dic];
            }
            else if ([body.action isEqualToString:GROUP_READ_CMD]) {
                //群组消息已读
                NSDictionary *ext = msg.ext;
                NSString *groupId = ext[CURRENT_CONVERSATIONID];
                NSArray *msgIds = ext[UPDATE_MSGID_LIST];
                NSString *readerName = msg.from;
                [[LocalDataTools tools] addDataToPlist:groupId msgIds:msgIds readerName:readerName];
            }
        }
    }
    
    if (set.count > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ShareLocations" object:set];
    }
}

- (void)ZYDDidUpdateConversationList:(NSArray *)aConversationList{
    NSMutableArray *conversationAry = [[NSMutableArray alloc] init];
    for (EMConversation *conversation in aConversationList) {
        if ([conversation.conversationId isEqualToString:@"admin"]) {            
        }else {
            [conversationAry addObject:conversation];
        }
    }
    [self ZYDDidUpdateConversationList:conversationAry];
}

@end
