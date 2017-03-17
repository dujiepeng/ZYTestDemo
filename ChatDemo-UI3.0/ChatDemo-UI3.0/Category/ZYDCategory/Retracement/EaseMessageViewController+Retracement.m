//
//  EaseMessageViewController+Retracement.m
//  ChatDemo-UI3.0
//
//  Created by 蒋月婷 on 17/3/15.
//  Copyright © 2017年 蒋月婷. All rights reserved.
//

#import "EaseMessageViewController+Retracement.h"
#import <objc/runtime.h>
#import "EaseCustomMessageCell.h"
#import "UIImage+EMGIF.h"
#import "EaseRetracementMessageCell.h"
#import "DefineKey.h"

@interface EaseMessageViewController()

@end
@implementation EaseMessageViewController (Retracement)

+ (void)load {
    
    Method oldTabelViewMethod = class_getInstanceMethod([EaseMessageViewController class], @selector(tableView:cellForRowAtIndexPath:));
    Method newTabelViewMethod = class_getInstanceMethod([EaseMessageViewController class], @selector(ZYDtableView:cellForRowAtIndexPath:));
    method_exchangeImplementations(oldTabelViewMethod, newTabelViewMethod);
    
    Method oldHightMethod = class_getInstanceMethod([EaseMessageViewController class], @selector(tableView: heightForRowAtIndexPath:));
    Method newHightMethod = class_getInstanceMethod([EaseMessageViewController class], @selector(ZYDtableView: heightForRowAtIndexPath:));
    method_exchangeImplementations(oldHightMethod, newHightMethod);
    
    
    
}


- (UITableViewCell *)ZYDtableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.dataArray objectAtIndex:indexPath.row];
    if ([object isKindOfClass:[NSString class]]) {
        
        NSString *TimeCellIdentifier = [EaseMessageTimeCell cellIdentifier];
        EaseMessageTimeCell *timeCell = (EaseMessageTimeCell *)[tableView dequeueReusableCellWithIdentifier:TimeCellIdentifier];
        
        if (timeCell == nil) {
            timeCell = [[EaseMessageTimeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TimeCellIdentifier];
            timeCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
        }
        timeCell.title = object;
        return timeCell;
        
    }
    else{
        id<IMessageModel> model = object;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(messageViewController:cellForMessageModel:)]) {
            NSDictionary *ext =  model.message.ext;
            if (ext[INSERT] != nil) {
                
                NSString *TimeCellIdentifier = [EaseRetracementMessageCell cellIdentifier];
                EaseRetracementMessageCell *timeCell = (EaseRetracementMessageCell *)[tableView dequeueReusableCellWithIdentifier:TimeCellIdentifier];
                
                if (timeCell == nil) {
                    timeCell = [[EaseRetracementMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TimeCellIdentifier];
                    timeCell.selectionStyle = UITableViewCellSelectionStyleNone;
                }
                
                timeCell.title = ext[INSERT];
                return timeCell;
            }
            else{
                return [self ZYDtableView:tableView cellForRowAtIndexPath:indexPath];
                
            }
        }
    }
    return [self ZYDtableView:tableView cellForRowAtIndexPath:indexPath];
    
}

- (CGFloat)ZYDtableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.dataArray objectAtIndex:indexPath.row];
    if ([object isKindOfClass:[NSString class]]) {
        return self.timeCellHeight;
    }
    else{
        id<IMessageModel> model = object;
        if (self.delegate && [self.delegate respondsToSelector:@selector(messageViewController:heightForMessageModel:withCellWidth:)]) {
            NSDictionary *ext =  model.message.ext;
            
            if (ext[INSERT] != nil) {
                NSString *TimeCellIdentifier = [EaseRetracementMessageCell cellIdentifier];
                EaseRetracementMessageCell *timeCell = (EaseRetracementMessageCell *)[tableView dequeueReusableCellWithIdentifier:TimeCellIdentifier];
                
                if (timeCell == nil) {
                    timeCell = [[EaseRetracementMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TimeCellIdentifier];
                    timeCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    CGFloat height = 22;
                    return height;
                }
            }else{
                return [self ZYDtableView:tableView heightForRowAtIndexPath:indexPath];
                
            }
            
            
        }else{
            return [self ZYDtableView:tableView heightForRowAtIndexPath:indexPath];
        }
        
        return [EaseBaseMessageCell cellHeightWithModel:model];
    }
}
@end
