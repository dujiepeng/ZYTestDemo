//
//  EaseLocationViewController+GoneAfterRead.m
//  ChatDemo-UI3.0
//
//  Created by EaseMob on 2017/3/15.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import "EaseLocationViewController+GoneAfterRead.h"
#import <objc/runtime.h>
@implementation EaseLocationViewController (GoneAfterRead)

- (id<IMessageModel>)locationModel
{
    return objc_getAssociatedObject(self, @selector(locationModel));
}

- (void)setLocationModel:(id<IMessageModel>)locationModel
{
    objc_setAssociatedObject(self, @selector(locationModel), locationModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<EaseLocationViewControllerDelegate>)locDelegate
{
    return objc_getAssociatedObject(self, @selector(locDelegate));
}

- (void)setLocDelegate:(id<EaseLocationViewControllerDelegate>)locDelegate
{
    objc_setAssociatedObject(self, @selector(locDelegate), locDelegate, OBJC_ASSOCIATION_ASSIGN);
}

+ (void)load
{
    Method viewDidLoad = class_getInstanceMethod([self class], @selector(viewDidLoad));
    Method FViewDidLoad = class_getInstanceMethod([self class], @selector(FViewDidLoad));
    method_exchangeImplementations(viewDidLoad, FViewDidLoad);
}

- (void)FViewDidLoad
{
    [self FViewDidLoad];
    self.navigationItem.leftBarButtonItem = nil;
    UIButton *leaveButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    [leaveButton setImage:[UIImage imageNamed:@"EaseUIResource.bundle/back"] forState:UIControlStateNormal];
    [leaveButton addTarget:self action:@selector(leaveLocationView) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leaveItem = [[UIBarButtonItem alloc] initWithCustomView:leaveButton];
    [self.navigationItem setLeftBarButtonItem:leaveItem];
}

- (void)leaveLocationView
{
    if (self.locDelegate && [self.locDelegate respondsToSelector:@selector(locationMessageReadAck:)]) {
        [self.locDelegate locationMessageReadAck:self.locationModel];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
