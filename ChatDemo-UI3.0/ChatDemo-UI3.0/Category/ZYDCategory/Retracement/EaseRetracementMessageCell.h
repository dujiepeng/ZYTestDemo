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

/*
 *  撤回提示显示字体
 */
@property (nonatomic) UIFont *titleLabelFont UI_APPEARANCE_SELECTOR; //default [UIFont systemFontOfSize:12]

/*
 *  撤回提示显示的颜色
 */
@property (nonatomic) UIColor *titleLabelColor UI_APPEARANCE_SELECTOR; //default [UIColor grayColor]

+ (NSString *)cellIdentifier;
@end
