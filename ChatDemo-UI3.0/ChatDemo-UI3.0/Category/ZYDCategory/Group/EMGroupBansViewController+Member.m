//
//  EMGroupBansViewController+Member.m
//  ChatDemo-UI3.0
//
//  Created by EaseMob on 2017/3/9.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import "EMGroupBansViewController+Member.h"
#import <objc/runtime.h>

@interface EMGroupBansViewController()<UIAlertViewDelegate>

@property (nonatomic, strong) EMGroup *group;
@property (nonatomic, strong) NSIndexPath *currentLongPressIndex;

@end

@implementation EMGroupBansViewController (Member)

- (NSObject *)group {
    
    return objc_getAssociatedObject(self, @selector(group));
}

- (void)setGroup:(NSObject *)group {
    
    objc_setAssociatedObject(self, @selector(group), group, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSObject *)currentLongPressIndex {
    
    return objc_getAssociatedObject(self, @selector(currentLongPressIndex));
}

- (void)setCurrentLongPressIndex:(NSObject *)currentLongPressIndex {
    
    objc_setAssociatedObject(self, @selector(currentLongPressIndex), currentLongPressIndex, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)load
{
    Method actionsheetAction = class_getInstanceMethod([self class], @selector(actionSheet:clickedButtonAtIndex:));
    Method newActionsheetAction = class_getInstanceMethod([self class], @selector(newActionSheet:clickedButtonAtIndex:));
    method_exchangeImplementations(actionsheetAction, newActionsheetAction);
}

- (void)newActionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex || self.currentLongPressIndex == nil) {
        return;
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"是否从群内移除" delegate:self cancelButtonTitle:@"YES" otherButtonTitles:@"NO", nil];
    [alert show];

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSIndexPath *indexPath = self.currentLongPressIndex;
    NSString *userName = [self.dataArray objectAtIndex:indexPath.row];
    self.currentLongPressIndex = nil;
    
    __weak typeof(self) weakSelf = self;
    if (alertView.cancelButtonIndex == buttonIndex) {
        
        [[EMClient sharedClient].groupManager unblockMembers:@[userName] fromGroup:self.group.groupId completion:^(EMGroup *aGroup, EMError *aError) {
            
            [weakSelf hideHud];
            if (!aError) {
                
                [weakSelf reloadTable:userName];
            } else {
                
                [weakSelf showHint:aError.description];
            }
        }];

    } else {
        
        [[EMClient sharedClient].groupManager addMembers:@[userName] toGroup:weakSelf.group.groupId message:nil completion:^(EMGroup *aGroup, EMError *aError) {
    
            [weakSelf hideHud];
            if (!aError) {
                
                [weakSelf reloadTable:userName];
            } else {
                
                [weakSelf showHint:@"Remove from blacklist failed"];
                
            }
        }];

    }

}

- (void)reloadTable:(NSString *)username {
    
    [self.dataArray removeObject:username];
    [self.tableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGroupDetail" object:self.group];
}

@end
