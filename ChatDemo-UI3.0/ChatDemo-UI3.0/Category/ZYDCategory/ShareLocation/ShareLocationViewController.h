//
//  ShareLocationViewController.h
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 28/02/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShareLocationViewController : UIViewController
@property (nonatomic) BOOL isSender; // 是否是位置共享的发起方

- (instancetype)initWithShareLocationToChatter:(NSString *)conversationChatter conversationType:(EMConversationType)conversationType;
@end
