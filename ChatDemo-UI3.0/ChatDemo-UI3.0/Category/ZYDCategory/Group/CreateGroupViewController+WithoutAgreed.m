//
//  CreateGroupViewController+WithoutAgreed.m
//  ChatDemo-UI3.0
//
//  Created by EaseMob on 2017/3/10.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import "CreateGroupViewController+WithoutAgreed.h"
#import "EMChooseViewController.h"
#import <objc/runtime.h>

@interface CreateGroupViewController()


@property (nonatomic, strong) UILabel *inviteeDetailLabel;


@end

static const char *withoutAgreedKey = "withoutAgreedKey";
@implementation CreateGroupViewController (WithoutAgreed)

- (UILabel *)inviteeDetailLabel
{
    return objc_getAssociatedObject(self, @selector(inviteeDetailLabel));
}

- (void)setInviteeDetailLabel:(UILabel *)inviteeDetailLabel
{
    objc_setAssociatedObject(self, @selector(inviteeDetailLabel), inviteeDetailLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)withoutAgreed
{
    return [objc_getAssociatedObject(self, withoutAgreedKey) boolValue];
}

- (void)setWithoutAgreed:(BOOL)withoutAgreed
{
    objc_setAssociatedObject(self, withoutAgreedKey,  @(withoutAgreed), OBJC_ASSOCIATION_ASSIGN);
}


+ (void)load
{
    Method viewDidLoad = class_getInstanceMethod([self class], @selector(viewDidLoad));
    Method myViewDidLoad = class_getInstanceMethod([self class], @selector(myViewDidLoad));
    method_exchangeImplementations(viewDidLoad, myViewDidLoad);
    
    Method old = class_getInstanceMethod([self class], @selector(viewController:didFinishSelectedSources:));
    Method new = class_getInstanceMethod([self class], @selector(myViewController:didFinishSelectedSources:));
    method_exchangeImplementations(old, new);
}

- (void)myViewDidLoad
{
    [self myViewDidLoad];
    [self setupMyUI];
}

- (BOOL)myViewController:(EMChooseViewController *)viewController didFinishSelectedSources:(NSArray *)selectedSources
{
    
    
    NSInteger maxUsersCount = 200;
    if ([selectedSources count] > (maxUsersCount - 1)) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"group.maxUserCount", nil) message:nil delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
        [alertView show];
        
        return NO;
    }
    
    [self showHudInView:self.view hint:NSLocalizedString(@"group.create.ongoing", @"create a group...")];
    
    NSMutableArray *source = [NSMutableArray array];
    for (NSString *username in selectedSources) {
        [source addObject:username];
    }
    
    EMGroupOptions *setting = [[EMGroupOptions alloc] init];
    setting.maxUsersCount = maxUsersCount;
    id objc = [self valueForKey:@"isMemberOn"];
    NSLog(@"objc -- %@",objc);
    if ([self valueForKey:@"isPublic"]) {
        if([self valueForKey:@"isMemberOn"])
        {
            setting.style = EMGroupStylePublicOpenJoin;
        }
        else{
            setting.style = EMGroupStylePublicJoinNeedApproval;
        }
    }
    else{
        if([self valueForKey:@"isMemberOn"])
        {
            setting.style = EMGroupStylePrivateMemberCanInvite;
        }
        else{
            setting.style = EMGroupStylePrivateOnlyOwnerInvite;
        }
    }
    if (self.withoutAgreed) {
        setting.IsInviteNeedConfirm = NO;
    } else {
        setting.IsInviteNeedConfirm = YES;
    }
    __weak CreateGroupViewController *weakSelf = self;
    NSString *username = [[EMClient sharedClient] currentUsername];
    NSString *text = ((UITextField *)[self valueForKey:@"textField"]).text;
    NSString *messageStr = [NSString stringWithFormat:NSLocalizedString(@"group.somebodyInvite", @"%@ invite you to join groups \'%@\'"), username, text];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        EMError *error = nil;
        EMGroup *group = [[EMClient sharedClient].groupManager createGroupWithSubject:text description:text invitees:source message:messageStr setting:setting error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf hideHud];
            if (group && !error) {
                [weakSelf showHint:NSLocalizedString(@"group.create.success", @"create group success")];
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }
            else{
                [weakSelf showHint:NSLocalizedString(@"group.create.fail", @"Failed to create a group, please operate again")];
            }
        });
    });
    return YES;
}


- (void)setupMyUI
{
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 270, 100, 35)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:14.0];
    label.numberOfLines = 2;
    label.text = @"被邀请人权限";
    
    UISwitch *needAgree = [[UISwitch alloc] initWithFrame:CGRectMake(CGRectGetMaxX(label.frame), 270, 50, 35)];
    needAgree.accessibilityIdentifier = @"invitee_permission";
    [needAgree addTarget:self action:@selector(inviteePermissionChanged:) forControlEvents:UIControlEventValueChanged];
    
    
    self.inviteeDetailLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(needAgree.frame), 270, 150, 35)];
    self.inviteeDetailLabel.backgroundColor = [UIColor clearColor];
    self.inviteeDetailLabel.textColor = [UIColor grayColor];
    self.inviteeDetailLabel.font = [UIFont systemFontOfSize:12.0];
    self.inviteeDetailLabel.numberOfLines = 2;
    self.inviteeDetailLabel.text = @"需要被邀请人同意";
    [self.view addSubview:label];
    [self.view addSubview:needAgree];
    [self.view addSubview:self.inviteeDetailLabel];
    
}

- (void)inviteePermissionChanged:(UISwitch *)sender
{
    self.withoutAgreed = sender.isOn;
    if (self.withoutAgreed) {
        
        self.inviteeDetailLabel.text = @"不需要被邀请人同意";
    } else {
        
        self.inviteeDetailLabel.text = @"需要被邀请人同意";
    }
    
}

@end
