//
//  EMConversation+Draft.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 02/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "EMConversation+Draft.h"
#define kDRAFT @"draft"

@implementation EMConversation (Draft)

#pragma mark - 草稿
- (NSString *)draft{
    return self.ext[kDRAFT];
}

- (void)setDraft:(NSString *)aDraft{
    NSMutableDictionary *dic = [self.ext mutableCopy];
    if (!dic) {
        dic = [[NSMutableDictionary alloc] init];
    }
    
    dic[kDRAFT] = aDraft;
    self.ext = dic;
}
@end
