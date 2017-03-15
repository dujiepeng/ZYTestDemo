//
//  EaseMessageReadManager+GoneAfterRead.h
//  ChatDemo-UI3.0
//
//  Created by EaseMob on 2017/3/14.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import "EaseMessageReadManager.h"

@protocol EaseMessageReadManagerDelegate <NSObject>

@optional

- (void)readMessageFinished:(id<IMessageModel>)model;

@end

@interface EaseMessageReadManager (GoneAfterRead)

@property (nonatomic, strong) id<IMessageModel>imageModel;

@property (nonatomic) id<EaseMessageReadManagerDelegate>readDelegate;

@end
