//
//  ChatViewController+ShareLocation.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 02/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "ChatViewController+ShareLocation.h"
#import "ShareLocationViewController.h"

@implementation ChatViewController (ShareLocation)

- (void)moreViewLocationAction:(EaseChatBarMoreView *)moreView {
    [self.chatToolbar endEditing:YES];
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *shareLocationAction = [UIAlertAction actionWithTitle:@"实时位置共享" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        ShareLocationViewController *shareLocationVC = [[ShareLocationViewController alloc] initWithShareLocationToChatter:self.conversation.conversationId conversationType:self.conversation.type];
        shareLocationVC.isSender = YES;
        [self.navigationController addChildViewController:shareLocationVC];
        [self.navigationController.view addSubview:shareLocationVC.view];
    }];
    
    UIAlertAction *sendLocationAction = [UIAlertAction actionWithTitle:@"发送地理位置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        EaseLocationViewController *locationController = [[EaseLocationViewController alloc] init];
        locationController.delegate = self;
        [self.navigationController pushViewController:locationController animated:YES];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertVC addAction:shareLocationAction];
    [alertVC addAction:sendLocationAction];
    [alertVC addAction:cancelAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)sendTextMessage:(NSString *)text withExt:(NSDictionary*)ext {
    [super sendTextMessage:text withExt:ext];
}

@end
