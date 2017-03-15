//
//  ChatDemoHelper+GroupMemberChange.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/3/14.
//  Copyright © 2017年 WYZ. All rights reserved.
//

#import "ChatDemoHelper+GroupMemberChange.h"

@implementation ChatDemoHelper (GroupMemberChange)

/*!
 *  \~chinese
 *  有用户加入群组
 *
 *  @param aGroup       加入的群组
 *  @param aUsername    加入者
 *
 *  \~english
 *  Delegate method will be invoked when a user joins a group.
 *
 *  @param aGroup       Joined group
 *  @param aUsername    The user who joined group
 */
- (void)userDidJoinGroup:(EMGroup *)aGroup user:(NSString *)aUsername {
    NSString *msg = [NSString stringWithFormat:@"用户%@进入群组【%@】",aUsername,aGroup.subject];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:msg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alertView show];
}


/*!
 *  \~chinese
 *  有用户离开群组
 *
 *  @param aGroup       离开的群组
 *  @param aUsername    离开者
 *
 *  \~english
 *  Delegate method will be invoked when a user leaves a group.
 *
 *  @param aGroup       Left group
 *  @param aUsername    The user who leaved group
 */
- (void)userDidLeaveGroup:(EMGroup *)aGroup user:(NSString *)aUsername {
    NSString *msg = [NSString stringWithFormat:@"成员%@离开群组【%@】",aUsername,aGroup.subject];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:msg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alertView show];
}

@end
