//
//  EaseLocationViewController+GoneAfterRead.h
//  ChatDemo-UI3.0
//
//  Created by EaseMob on 2017/3/15.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import "EaseLocationViewController.h"

@protocol EaseLocationViewControllerDelegate <NSObject>

@optional
- (void)locationMessageReadAck:(id<IMessageModel>)model;

@end

@interface EaseLocationViewController (GoneAfterRead)

@property (nonatomic, strong)id <IMessageModel>locationModel;

@property (nonatomic) id<EaseLocationViewControllerDelegate>locDelegate;
@end
