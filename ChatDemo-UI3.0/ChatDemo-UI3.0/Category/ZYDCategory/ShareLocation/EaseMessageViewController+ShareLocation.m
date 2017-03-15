//
//  EaseMessageViewController+ShareLocation.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 09/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "EaseMessageViewController+ShareLocation.h"
#import "ShareLocationViewController.h"
#import <objc/runtime.h>

@implementation EaseMessageViewController (ShareLocation)


- (void)shareLocationMessageHasPassed {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"是否发起位置共享" message:@"发起后对方能实时看到您的位置" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *shareLocationAction = [UIAlertAction actionWithTitle:@"发起" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        ShareLocationViewController *shareLocationVC = [[ShareLocationViewController alloc] initWithShareLocationToChatter:self.conversation.conversationId conversationType:self.conversation.type];
        [self.navigationController addChildViewController:shareLocationVC];
        [self.navigationController.view addSubview:shareLocationVC.view];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertVC addAction:shareLocationAction];
    [alertVC addAction:cancelAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}

@end
