//
//  EaseConversationModel+Top.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 27/02/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "EaseConversationModel+Top.h"
#define kUPTOTOP @"upToTop"

@implementation EaseConversationModel (Top)

#pragma mark - 置顶
- (double)topTime {
    return [self.conversation.ext[kUPTOTOP] doubleValue];
}

- (BOOL)isTop {
    return [self.conversation.ext[kUPTOTOP] boolValue];
}

- (void)upToTop:(void(^)())completion {
    NSMutableDictionary *dic = [self.conversation.ext mutableCopy];
    if (!dic) {
        dic = [[NSMutableDictionary alloc] init];
    }
    
    dic[kUPTOTOP] = [NSNumber numberWithDouble:[NSDate date].timeIntervalSince1970];
    self.conversation.ext = dic;
    if(completion){
        completion();
    }
}

- (void)upToNormal:(void(^)())completion {
    NSMutableDictionary *dic = [self.conversation.ext mutableCopy];
    if (dic && dic[kUPTOTOP]) {
        dic[kUPTOTOP] = nil;
    }
    
    self.conversation.ext = dic;
    if(completion){
        completion();
    }
}

@end
