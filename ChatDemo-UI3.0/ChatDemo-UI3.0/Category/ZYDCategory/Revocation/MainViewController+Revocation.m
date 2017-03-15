//
//  MainViewController+Revocation.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 14/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "MainViewController+Revocation.h"
#import "RevocationManager.h"
#import "DefineKey.h"
#import <objc/runtime.h>

@implementation MainViewController (Revocation)
+ (void)load {
    Method viewDidLoad = class_getInstanceMethod([self class], @selector(viewDidLoad));
    Method revocationViewDidLoad = class_getInstanceMethod([self class], @selector(revocationViewDidLoad));
    method_exchangeImplementations(viewDidLoad, revocationViewDidLoad);
}

- (void)revocationViewDidLoad {
    [self revocationViewDidLoad];
    [RevocationManager sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setupUnreadMessageCount)
                                                 name:REVOCATION_UPDATE_UNREAD_COUNT
                                               object:nil];
}

@end
