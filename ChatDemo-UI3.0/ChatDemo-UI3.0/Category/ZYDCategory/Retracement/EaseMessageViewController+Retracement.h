//
//  EaseMessageViewController+Retracement.h
//  ChatDemo-UI3.0
//
//  Created by 蒋月婷 on 17/3/15.
//  Copyright © 2017年 蒋月婷. All rights reserved.
//

#import "EaseMessageViewController.h"

@interface EaseMessageViewController (Retracement)
@property (weak, nonatomic) id<EaseMessageViewControllerDelegate> delegate;
@property (weak, nonatomic) id<EaseMessageViewControllerDataSource> dataSource;

@end
