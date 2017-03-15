//
//  RevocationManager.h
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 14/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatViewController.h"

@interface RevocationManager : NSObject
@property (nonatomic, weak) ChatViewController *chatVC;
+ (RevocationManager *)sharedInstance;
@end
