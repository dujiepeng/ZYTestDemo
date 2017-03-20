//
//  EaseRetracementMessageCell.h
//  ChatDemo-UI3.0
//
//  Created by 蒋月婷 on 17/3/14.
//  Copyright © 2017年 蒋月婷. All rights reserved.
//

#import <UIKit/UIKit.h>
/** @brief 撤回提示的cell */

@interface EaseRetracementMessageCell : UITableViewCell

@property (strong, nonatomic) NSString *title;

+ (NSString *)cellIdentifier;
@end
