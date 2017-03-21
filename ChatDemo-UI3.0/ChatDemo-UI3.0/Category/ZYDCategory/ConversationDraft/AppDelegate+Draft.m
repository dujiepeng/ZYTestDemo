//
//  AppDelegate+Draft.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 21/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "AppDelegate+Draft.h"
#import "DefineKey.h"

@implementation AppDelegate (Draft)
- (void)applicationWillResignActive:(UIApplication *)application {
    [[NSNotificationCenter defaultCenter] postNotificationName:DRAFT_NOTI_KEY object:nil];
}
@end
