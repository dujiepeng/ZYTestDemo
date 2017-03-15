//
//  AppDelegate+ShareFiles.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 15/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "AppDelegate+ShareFiles.h"
#import "ShareFilesViewController.h"
#import "EMNavigationController.h"
#import "EaseMessageModel.h"

@implementation AppDelegate (ShareFiles)
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(nonnull NSDictionary<NSString *,id> *)options
{
 
    NSLog(@"url -- %@",url);

    if(self.window.rootViewController) {
        id vc = self.window.rootViewController;
        if ([vc isKindOfClass:[EMNavigationController class]]) {
            EMNavigationController *emNav = (EMNavigationController *)vc;
            if ([emNav.topViewController isKindOfClass:[MainViewController class]]) {
                MainViewController *mainVC = (MainViewController *)emNav.topViewController;
                ShareFilesViewController *shareFilesVC = [[ShareFilesViewController alloc] initWithUrl:url];
                [mainVC.navigationController pushViewController:shareFilesVC animated:NO];
                return YES;
            }
        }
        
    }

    
    return YES;
}
@end
